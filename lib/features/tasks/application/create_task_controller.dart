import 'package:flutter/foundation.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/idempotency_key.dart';
import 'package:tiyn_app/features/tasks/data/new_task.dart';
import 'package:tiyn_app/features/tasks/data/task.dart';

enum CreatePhase {
  /// Fields editable, nothing pending.
  editing,
  sending,

  /// The server said no (4xx): nothing was created. Fields stay editable.
  rejected,

  /// Timeout, network error, 5xx or an unreadable answer: the task may exist.
  /// Fields are locked; the only ways out are "Try again" (same key) and an
  /// explicit [CreateTaskController.unlockToEdit].
  ambiguous,
}

/// One user action = one `Idempotency-Key` (ADR-0001).
///
/// - The key is made when the form opens, not per tap.
/// - After a rejection nothing exists, so the user may edit; the first edit
///   makes a new key (the server refuses a changed payload under an old one).
/// - After an ambiguous failure the same payload is resent under the same key,
///   so a task that did get created is returned instead of duplicated.
///   Editing then needs an explicit step, because it gives up that protection.
class CreateTaskController extends ChangeNotifier {
  CreateTaskController({required this._send, IdempotencyKey Function()? newKey})
    : _newKey = newKey ?? IdempotencyKey.generate {
    key = _newKey();
  }

  final Future<Task> Function(NewTask, IdempotencyKey) _send;
  final IdempotencyKey Function() _newKey;

  late IdempotencyKey key;
  CreatePhase phase = CreatePhase.editing;
  ApiException? error;

  /// The payload of the attempt that failed ambiguously.
  NewTask? pending;
  Task? created;
  bool _keyRotatedSinceFailure = false;

  bool get isLocked =>
      phase == CreatePhase.sending || phase == CreatePhase.ambiguous;

  /// Sends [task]. Ignored while a request is in flight. In the ambiguous
  /// phase the original payload is resent, whatever is passed.
  Future<bool> submit(NewTask task) async {
    if (phase == CreatePhase.sending) return false;
    final payload = phase == CreatePhase.ambiguous ? pending! : task;
    phase = CreatePhase.sending;
    error = null;
    notifyListeners();
    try {
      created = await _send(payload, key);
      phase = CreatePhase.editing;
      pending = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e;
      final status = e.statusCode;
      final rejected = status != null && status >= 400 && status < 500;
      if (rejected) {
        phase = CreatePhase.rejected;
        pending = null;
        _keyRotatedSinceFailure = false;
      } else {
        phase = CreatePhase.ambiguous;
        pending = payload;
      }
      notifyListeners();
      return false;
    }
  }

  /// The user changed a field. After a rejection the payload is no longer the
  /// one the server saw, so it gets a new key.
  void noteEdited() {
    if (phase == CreatePhase.rejected && !_keyRotatedSinceFailure) {
      key = _newKey();
      _keyRotatedSinceFailure = true;
    }
  }

  /// "Edit details" after an ambiguous failure. A duplicate is possible from
  /// here on, so this must only follow the user's explicit confirmation.
  void unlockToEdit() {
    if (phase != CreatePhase.ambiguous) return;
    key = _newKey();
    pending = null;
    error = null;
    phase = CreatePhase.editing;
    notifyListeners();
  }
}
