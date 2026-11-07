import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/idempotency_key.dart';
import 'package:tiyn_app/features/tasks/data/task.dart';

const maxProofBytes = 5 * 1024 * 1024;
const _firstQuality = 85;
const _fallbackQuality = 60;
const _longestSide = 2048;

enum PhotoOrigin { camera, gallery }

abstract interface class PhotoPicker {
  /// The chosen image as the phone stores it (JPEG, HEIF, WebP, PNG...), or
  /// null if the user backed out.
  Future<Uint8List?> pick(PhotoOrigin origin);
}

class ImagePickerPhotoPicker implements PhotoPicker {
  @override
  Future<Uint8List?> pick(PhotoOrigin origin) async {
    // No quality or size here: the app encodes the photo itself.
    final file = await ImagePicker().pickImage(
      source: origin == PhotoOrigin.camera
          ? ImageSource.camera
          : ImageSource.gallery,
    );
    return file?.readAsBytes();
  }
}

abstract interface class PhotoEncoder {
  /// [source] re-encoded as JPEG, or null if it cannot be decoded.
  Future<Uint8List?> toJpeg(Uint8List source, {required int quality});
}

class FlutterPhotoEncoder implements PhotoEncoder {
  @override
  Future<Uint8List?> toJpeg(Uint8List source, {required int quality}) async {
    try {
      // EXIF is dropped (the default) and the orientation is applied, so a
      // photo never leaves the phone with its location in it.
      return await FlutterImageCompress.compressWithList(
        source,
        format: CompressFormat.jpeg,
        quality: quality,
        minWidth: _longestSide,
        minHeight: _longestSide,
      );
    } on Object {
      return null;
    }
  }
}

enum ProofProblem { unreadable, tooLarge }

class ProofException implements Exception {
  const ProofException(this.problem);

  final ProofProblem problem;

  @override
  String toString() => 'ProofException($problem)';
}

/// Always JPEG, whatever the phone gave us (HEIF, WebP and PNG are never
/// rejected for their type). The size limit applies to what is sent, so it is
/// checked after encoding: once at normal quality, once more at a lower one.
Future<Uint8List> encodeForUpload(
  PhotoEncoder encoder,
  Uint8List source,
) async {
  final first = await encoder.toJpeg(source, quality: _firstQuality);
  if (first == null || first.isEmpty) {
    throw const ProofException(ProofProblem.unreadable);
  }
  if (first.length <= maxProofBytes) return first;

  final smaller = await encoder.toJpeg(source, quality: _fallbackQuality);
  if (smaller == null || smaller.isEmpty || smaller.length > maxProofBytes) {
    throw const ProofException(ProofProblem.tooLarge);
  }
  return smaller;
}

/// One key per attempt (ADR-0001): a retry of the same payload reuses it, a
/// different payload (another photo, an edited note) gets a new one, because
/// the server refuses a changed payload under an old key.
class ProofKeys {
  Object? _payload;
  IdempotencyKey? _key;

  IdempotencyKey keyFor(Object payload) {
    if (_key == null || _payload != payload) {
      _payload = payload;
      _key = IdempotencyKey.generate();
    }
    return _key!;
  }
}

typedef SendText = Future<Task> Function(String text, IdempotencyKey key);
typedef SendPhoto = Future<Task> Function(Uint8List jpeg, IdempotencyKey key);

/// Picks, encodes and sends one proof, and remembers what failed so "Try
/// again" resends the same thing under the same key.
class ProofSubmitter extends ChangeNotifier {
  ProofSubmitter({
    required this.sendText,
    required this.sendPhoto,
    required this.picker,
    required this.encoder,
    ProofKeys? keys,
  }) : keys = keys ?? ProofKeys();

  final SendText sendText;
  final SendPhoto sendPhoto;
  final PhotoPicker picker;
  final PhotoEncoder encoder;
  final ProofKeys keys;

  bool busy = false;

  /// An [ApiException] or a [ProofException]; null when the last try worked
  /// or nothing was tried.
  Object? error;
  Task? submitted;

  Uint8List? _photo;
  String? _text;

  bool get canRetry => error != null && (_photo != null || _text != null);

  Future<bool> submitText(String text) {
    _photo = null;
    _text = text;
    return _run();
  }

  Future<bool> submitPhoto(PhotoOrigin origin) async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final raw = await picker.pick(origin);
      if (raw == null) {
        busy = false;
        notifyListeners();
        return false;
      }
      _photo = await encodeForUpload(encoder, raw);
      _text = null;
    } on ProofException catch (e) {
      error = e;
      busy = false;
      notifyListeners();
      return false;
    }
    busy = false;
    return _run();
  }

  /// Resends the last photo or note, same key.
  Future<bool> retry() => _run();

  Future<bool> _run() async {
    if (busy) return false;
    final photo = _photo;
    final text = _text;
    if (photo == null && text == null) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      submitted = photo != null
          ? await sendPhoto(
              photo,
              keys.keyFor('photo:${photo.length}:${Object.hashAll(photo)}'),
            )
          : await sendText(text!, keys.keyFor('text:$text'));
      busy = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e;
      busy = false;
      notifyListeners();
      return false;
    }
  }
}
