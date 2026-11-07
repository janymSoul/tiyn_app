import 'package:flutter/foundation.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/idempotency_key.dart';
import 'package:tiyn_app/features/payouts/data/payout.dart';

@immutable
class PayoutRequest {
  const PayoutRequest({required this.parentId, required this.amount});

  final String parentId;
  final Money amount;

  @override
  bool operator ==(Object other) =>
      other is PayoutRequest &&
      other.parentId == parentId &&
      other.amount == amount;

  @override
  int get hashCode => Object.hash(parentId, amount);
}

enum RequestPhase {
  /// Fields editable, nothing pending.
  editing,
  sending,

  /// The server said no (4xx): nothing was created. Fields stay editable.
  rejected,

  /// Timeout, network error, 5xx or an unreadable answer: the request may
  /// exist. Fields are locked; the ways out are "Try again" (same key) and an
  /// explicit [RequestPayoutController.unlockToEdit].
  ambiguous,
}

/// One cash-out attempt = one `Idempotency-Key`, the same rules as creating a
/// task (Phase 1 P4):
/// - The key is made when the form opens, not per tap.
/// - After a rejection nothing exists; the first edit makes a new key, because
///   the server refuses a changed payload under an old one.
/// - After an ambiguous failure the identical payload is resent under the same
///   key, so a request that did land is returned, not duplicated.
class RequestPayoutController extends ChangeNotifier {
  RequestPayoutController({
    required this._send,
    IdempotencyKey Function()? newKey,
  }) : _newKey = newKey ?? IdempotencyKey.generate {
    key = _newKey();
  }

  final Future<Payout> Function(PayoutRequest, IdempotencyKey) _send;
  final IdempotencyKey Function() _newKey;

  late IdempotencyKey key;
  RequestPhase phase = RequestPhase.editing;
  ApiException? error;

  /// The payload of the attempt that failed ambiguously.
  PayoutRequest? pending;
  Payout? created;
  bool _keyRotatedSinceFailure = false;

  bool get isLocked =>
      phase == RequestPhase.sending || phase == RequestPhase.ambiguous;

  /// Sends [request]. Ignored while a request is in flight. In the ambiguous
  /// phase the original payload is resent, whatever is passed.
  Future<bool> submit(PayoutRequest request) async {
    if (phase == RequestPhase.sending) return false;
    final payload = phase == RequestPhase.ambiguous ? pending! : request;
    phase = RequestPhase.sending;
    error = null;
    notifyListeners();
    try {
      created = await _send(payload, key);
      phase = RequestPhase.editing;
      pending = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e;
      final status = e.statusCode;
      final rejected = status != null && status >= 400 && status < 500;
      if (rejected) {
        phase = RequestPhase.rejected;
        pending = null;
        _keyRotatedSinceFailure = false;
      } else {
        phase = RequestPhase.ambiguous;
        pending = payload;
      }
      notifyListeners();
      return false;
    }
  }

  /// The user changed the amount or the parent. After a rejection the payload
  /// is no longer the one the server saw, so it gets a new key.
  void noteEdited() {
    if (phase == RequestPhase.rejected && !_keyRotatedSinceFailure) {
      key = _newKey();
      _keyRotatedSinceFailure = true;
    }
  }

  /// "Edit details" after an ambiguous failure. A refusal is possible from
  /// here on, so this must only follow the user's explicit confirmation.
  void unlockToEdit() {
    if (phase != RequestPhase.ambiguous) return;
    key = _newKey();
    pending = null;
    error = null;
    phase = RequestPhase.editing;
    notifyListeners();
  }
}
