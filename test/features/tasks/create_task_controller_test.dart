import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/idempotency_key.dart';
import 'package:tiyn_app/features/tasks/application/create_task_controller.dart';
import 'package:tiyn_app/features/tasks/data/new_task.dart';
import 'package:tiyn_app/features/tasks/data/task.dart';

import '../../helpers/fake_tasks.dart';

NewTask _task([String title = 'Wash dishes']) => NewTask(
  teenId: 'teen',
  title: title,
  reward: const Money.kzt(150000),
  deadlineAt: DateTime.utc(2026, 12, 1),
);

({CreateTaskController controller, List<({NewTask task, String key})> sent})
_make(Future<Task> Function(int attempt) outcome) {
  final sent = <({NewTask task, String key})>[];
  var keys = 0;
  final controller = CreateTaskController(
    send: (task, key) {
      sent.add((task: task, key: key.value));
      return outcome(sent.length);
    },
    newKey: () => IdempotencyKey('key-${++keys}'),
  );
  return (controller: controller, sent: sent);
}

ApiException _status(int status, [String code = 'x']) =>
    ApiException(code: code, statusCode: status);

void main() {
  test('the key exists as soon as the form opens', () {
    final c = _make((_) async => fakeTask()).controller;
    expect(c.key.value, 'key-1');
    expect(c.phase, CreatePhase.editing);
  });

  test('success: sent once under the opening key', () async {
    final s = _make((_) async => fakeTask(id: 'made'));
    expect(await s.controller.submit(_task()), isTrue);
    expect(s.sent.map((e) => e.key), ['key-1']);
    expect(s.controller.created!.id, 'made');
    expect(s.controller.phase, CreatePhase.editing);
  });

  test('a second tap while the first is in flight sends nothing', () async {
    final gate = Completer<Task>();
    final s = _make((_) => gate.future);
    final first = s.controller.submit(_task());
    expect(s.controller.phase, CreatePhase.sending);
    expect(await s.controller.submit(_task()), isFalse);
    expect(await s.controller.submit(_task()), isFalse);
    gate.complete(fakeTask());
    expect(await first, isTrue);
    expect(s.sent, hasLength(1));
  });

  group('rejected (4xx): nothing was created', () {
    test('fields stay editable and the key is kept until an edit', () async {
      final s = _make((_) async => throw _status(422, 'invalid_reward'));
      expect(await s.controller.submit(_task()), isFalse);
      expect(s.controller.phase, CreatePhase.rejected);
      expect(s.controller.isLocked, isFalse);
      expect(s.controller.error!.code, 'invalid_reward');
      expect(s.controller.key.value, 'key-1');
    });

    test('resending without any edit reuses the key', () async {
      final s = _make((_) async => throw _status(422));
      await s.controller.submit(_task());
      await s.controller.submit(_task());
      expect(s.sent.map((e) => e.key), ['key-1', 'key-1']);
    });

    test('the first edit makes a new key, later edits keep that one', () async {
      final s = _make((i) async => i < 4 ? throw _status(422) : fakeTask());
      await s.controller.submit(_task());
      s.controller.noteEdited();
      expect(s.controller.key.value, 'key-2');
      s.controller.noteEdited();
      s.controller.noteEdited();
      expect(s.controller.key.value, 'key-2');

      await s.controller.submit(_task('Edited'));
      expect(s.sent.last.key, 'key-2');
      expect(s.sent.last.task.title, 'Edited');

      // Rejected again, then edited again: another new key.
      await s.controller.submit(_task('Edited'));
      s.controller.noteEdited();
      expect(s.controller.key.value, 'key-3');
    });

    test('edits before any failure do not burn keys', () {
      final c = _make((_) async => fakeTask()).controller;
      c.noteEdited();
      c.noteEdited();
      expect(c.key.value, 'key-1');
    });

    test('403 and 409 count as rejected too', () async {
      for (final status in [400, 403, 409, 422]) {
        final s = _make((_) async => throw _status(status));
        await s.controller.submit(_task());
        expect(s.controller.phase, CreatePhase.rejected, reason: '$status');
      }
    });
  });

  group('ambiguous: the task may exist', () {
    final failures = <String, ApiException>{
      'timeout': const ApiException(code: 'timeout'),
      'network error': const ApiException(code: 'network_error'),
      '500': _status(500, 'internal_error'),
      '503': _status(503),
      'unreadable 201': _status(201, 'invalid_response'),
      'unreadable answer': const ApiException(code: 'invalid_response'),
    };

    for (final entry in failures.entries) {
      test('${entry.key} locks the form', () async {
        final s = _make((_) async => throw entry.value);
        await s.controller.submit(_task());
        expect(s.controller.phase, CreatePhase.ambiguous);
        expect(s.controller.isLocked, isTrue);
        expect(s.controller.pending, _task());
      });
    }

    test('Try again resends the same payload under the same key', () async {
      final s = _make(
        (i) async => i < 3
            ? throw const ApiException(code: 'timeout')
            : fakeTask(id: 'once'),
      );
      await s.controller.submit(_task());
      await s.controller.submit(_task('ignored: the fields are locked'));
      expect(s.sent.map((e) => e.key), ['key-1', 'key-1']);
      expect(s.sent.map((e) => e.task.title), ['Wash dishes', 'Wash dishes']);

      expect(await s.controller.submit(_task()), isTrue);
      expect(s.sent.map((e) => e.key), ['key-1', 'key-1', 'key-1']);
      expect(s.controller.created!.id, 'once');
      expect(s.controller.pending, isNull);
    });

    test('edits do not rotate the key while locked', () async {
      final s = _make((_) async => throw const ApiException(code: 'timeout'));
      await s.controller.submit(_task());
      s.controller.noteEdited();
      expect(s.controller.key.value, 'key-1');
    });

    test(
      'unlockToEdit is the explicit step: new key, fields editable',
      () async {
        final s = _make((_) async => throw const ApiException(code: 'timeout'));
        await s.controller.submit(_task());
        s.controller.unlockToEdit();
        expect(s.controller.phase, CreatePhase.editing);
        expect(s.controller.isLocked, isFalse);
        expect(s.controller.key.value, 'key-2');
        expect(s.controller.pending, isNull);
        expect(s.controller.error, isNull);
      },
    );

    test('a retry that is rejected turns into rejected, unlocked', () async {
      final s = _make(
        (i) async =>
            throw i == 1 ? const ApiException(code: 'timeout') : _status(422),
      );
      await s.controller.submit(_task());
      await s.controller.submit(_task());
      expect(s.controller.phase, CreatePhase.rejected);
      expect(s.controller.isLocked, isFalse);
    });

    test('unlockToEdit does nothing outside the ambiguous phase', () async {
      final c = _make((_) async => fakeTask()).controller;
      c.unlockToEdit();
      expect(c.key.value, 'key-1');
    });
  });
}
