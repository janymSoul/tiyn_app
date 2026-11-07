import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/idempotency_key.dart';
import 'package:tiyn_app/features/tasks/application/proof_upload.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

import '../../helpers/fake_tasks.dart';

class _Picker implements PhotoPicker {
  _Picker(this.bytes);
  Uint8List? bytes;
  @override
  Future<Uint8List?> pick(PhotoOrigin origin) async => bytes;
}

/// Returns [sizes] per quality; null means "cannot decode".
class _Encoder implements PhotoEncoder {
  _Encoder(this.sizeAt);
  final int? Function(int quality) sizeAt;
  final qualities = <int>[];
  @override
  Future<Uint8List?> toJpeg(Uint8List source, {required int quality}) async {
    qualities.add(quality);
    final size = sizeAt(quality);
    return size == null ? null : Uint8List(size);
  }
}

void main() {
  group('encodeForUpload', () {
    test(
      're-encodes whatever it is given and sends one pass if small',
      () async {
        final encoder = _Encoder((_) => 1000);
        final out = await encodeForUpload(encoder, Uint8List.fromList([1, 2]));
        expect(out.length, 1000);
        expect(encoder.qualities, [85]);
      },
    );

    test('checks the size after encoding and tries a lower quality', () async {
      final encoder = _Encoder((q) => q == 85 ? maxProofBytes + 1 : 2000);
      final out = await encodeForUpload(encoder, Uint8List(10));
      expect(out.length, 2000);
      expect(encoder.qualities, [85, 60]);
    });

    test('a big raw file that encodes small is accepted', () async {
      final encoder = _Encoder((_) => 3000);
      final out = await encodeForUpload(encoder, Uint8List(maxProofBytes * 2));
      expect(out.length, 3000);
    });

    test('too large after both passes', () async {
      final encoder = _Encoder((_) => maxProofBytes + 1);
      expect(
        () => encodeForUpload(encoder, Uint8List(10)),
        throwsA(
          isA<ProofException>().having(
            (e) => e.problem,
            'problem',
            ProofProblem.tooLarge,
          ),
        ),
      );
    });

    test('undecodable input is unreadable, not a type rejection', () async {
      final encoder = _Encoder((_) => null);
      expect(
        () => encodeForUpload(encoder, Uint8List(10)),
        throwsA(
          isA<ProofException>().having(
            (e) => e.problem,
            'problem',
            ProofProblem.unreadable,
          ),
        ),
      );
    });
  });

  group('ProofSubmitter', () {
    late FakeTaskRepository repo;
    setUp(() => repo = FakeTaskRepository([fakeTask()]));

    ProofSubmitter make({Uint8List? photo}) => ProofSubmitter(
      sendText: (text, key) => repo.submitText('t1', text, key: key),
      sendPhoto: (jpeg, key) => repo.submitPhoto(
        't1',
        bytes: jpeg,
        filename: 'proof.jpg',
        contentType: 'image/jpeg',
        key: key,
      ),
      picker: _Picker(photo),
      encoder: _Encoder((_) => 100),
    );

    test('retry after a timeout reuses the same key', () async {
      final s = make();
      var fail = true;
      repo.onSubmit = () async {
        if (fail) throw const ApiException(code: 'timeout');
      };
      expect(await s.submitText('done'), isFalse);
      expect(s.canRetry, isTrue);
      fail = false;
      expect(await s.retry(), isTrue);
      expect(repo.submissions, hasLength(2));
      expect(repo.submissions[0].key, repo.submissions[1].key);
      expect(s.submitted?.state, TaskState.submitted);
    });

    test('an edited note gets a new key', () async {
      final s = make();
      repo.onSubmit = () async =>
          throw const ApiException(code: 'x', statusCode: 422);
      await s.submitText('one');
      await s.submitText('two');
      expect(repo.submissions[0].key, isNot(repo.submissions[1].key));
    });

    test('the same note sent again keeps its key', () async {
      final s = make();
      repo.onSubmit = () async => throw const ApiException(code: 'timeout');
      await s.submitText('same');
      await s.submitText('same');
      expect(repo.submissions[0].key, repo.submissions[1].key);
    });

    test('a photo is sent as JPEG bytes and retried with its key', () async {
      final s = make(photo: Uint8List.fromList([9, 9, 9]));
      var fail = true;
      repo.onSubmit = () async {
        if (fail) throw const ApiException(code: 'network_error');
      };
      expect(await s.submitPhoto(PhotoOrigin.gallery), isFalse);
      fail = false;
      expect(await s.retry(), isTrue);
      expect(repo.submissions.map((e) => e.photo?.length), [100, 100]);
      expect(repo.submissions[0].key, repo.submissions[1].key);
    });

    test('backing out of the picker sends nothing', () async {
      final s = make();
      expect(await s.submitPhoto(PhotoOrigin.camera), isFalse);
      expect(repo.submissions, isEmpty);
      expect(s.error, isNull);
      expect(s.busy, isFalse);
    });

    test('an unreadable photo is an error with nothing to retry', () async {
      final s = ProofSubmitter(
        sendText: (_, _) => throw StateError('no'),
        sendPhoto: (_, _) => throw StateError('no'),
        picker: _Picker(Uint8List(5)),
        encoder: _Encoder((_) => null),
      );
      expect(await s.submitPhoto(PhotoOrigin.camera), isFalse);
      expect(s.error, isA<ProofException>());
      expect(s.canRetry, isFalse);
    });
  });

  test('IdempotencyKey sanity: keys differ per generate', () {
    expect(IdempotencyKey.generate(), isNot(IdempotencyKey.generate()));
  });
}
