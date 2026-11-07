import 'package:flutter/foundation.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/idempotency_key.dart';

enum SubmitPhase {
  /// Fields editable, nothing pending.
  editing,
  sending,

  /// The server said no (4xx): nothing was created. Fields stay editable.
  rejected,

  /// Timeout, network error, 5xx or an unreadable answer: the thing may
  /// exist. Fields are locked; the only ways out are "Try again" (same key)
  /// and an explicit [IdempotentSubmitController.unlockToEdit].
  ambiguous,
}

/// One user action = one `Idempotency-Key` (ADR-0001). Shared by every form
/// that creates something through a keyed `POST`, so the key rules live in one
/// place. [P] is the payload the user fills in, [R] what the server returns.
///
/// - The key is made when the form opens, not per tap.
/// - After a rejection nothing exists, so the user may edit; the first edit
///   makes a new key (the server refuses a changed payload under an old one).
/// - After an ambiguous failure the same payload is resent under the same key,
///   so something that did get created is returned instead of duplicated.
///   Editing then needs an explicit step, because it gives up that protection.
class IdempotentSubmitController<P, R> extends ChangeNotifier {
  IdempotentSubmitController({
    required this._send,
    IdempotencyKey Function()? newKey,
  }) : _newKey = newKey ?? IdempotencyKey.generate {
    key = _newKey();
  }

  final Future<R> Function(P, IdempotencyKey) _send;
  final IdempotencyKey Function() _newKey;

  late IdempotencyKey key;
  SubmitPhase phase = SubmitPhase.editing;
  ApiException? error;

  /// The payload of the attempt that failed ambiguously.
  P? pending;
  R? created;
  bool _keyRotatedSinceFailure = false;

  bool get isLocked =>
      phase == SubmitPhase.sending || phase == SubmitPhase.ambiguous;

  /// Sends [payload]. Ignored while a request is in flight. In the ambiguous
  /// phase the original payload is resent, whatever is passed.
  Future<bool> submit(P payload) async {
    if (phase == SubmitPhase.sending) return false;
    final toSend = phase == SubmitPhase.ambiguous ? pending as P : payload;
    phase = SubmitPhase.sending;
    error = null;
    notifyListeners();
    try {
      created = await _send(toSend, key);
      phase = SubmitPhase.editing;
      pending = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e;
      final status = e.statusCode;
      final rejected = status != null && status >= 400 && status < 500;
      if (rejected) {
        phase = SubmitPhase.rejected;
        pending = null;
        _keyRotatedSinceFailure = false;
      } else {
        phase = SubmitPhase.ambiguous;
        pending = toSend;
      }
      notifyListeners();
      return false;
    }
  }

  /// The user changed a field. After a rejection the payload is no longer the
  /// one the server saw, so it gets a new key.
  void noteEdited() {
    if (phase == SubmitPhase.rejected && !_keyRotatedSinceFailure) {
      key = _newKey();
      _keyRotatedSinceFailure = true;
    }
  }

  /// "Edit details" after an ambiguous failure. A duplicate is possible from
  /// here on, so this must only follow the user's explicit confirmation.
  void unlockToEdit() {
    if (phase != SubmitPhase.ambiguous) return;
    key = _newKey();
    pending = null;
    error = null;
    phase = SubmitPhase.editing;
    notifyListeners();
  }
}
