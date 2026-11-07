import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/features/tasks/data/proof.dart';
import 'package:tiyn_app/features/tasks/data/task.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

Map<String, Object?> _full() => {
  'id': 't1',
  'teenId': 'teen',
  'parentId': 'parent',
  'kind': 'MILESTONE',
  'title': 'School term',
  'description': 'Read the books',
  'rewardAmount': 150050,
  'penaltyAmount': 20000,
  'currency': 'KZT',
  'state': 'SUBMITTED',
  'deadlineAt': '2026-11-03T18:00:00Z',
  'submittedAt': '2026-11-02T10:30:00Z',
  'decidedAt': '2026-11-02T12:00:00Z',
  'decisionNote': 'Nice',
  'milestoneId': 'm1',
  'approvedTasks': 2,
  'totalTasks': 5,
};

// We write timestamps with milliseconds; the backend's shorter form means the
// same instant.
Map<String, Object?> _wire(Map<String, Object?> json) => {
  for (final e in json.entries)
    e.key: e.key.endsWith('At') && e.value is String
        ? (e.value! as String).replaceFirst('Z', '.000Z')
        : e.value,
};

Matcher _invalidResponse() => throwsA(
  isA<ApiException>().having((e) => e.code, 'code', 'invalid_response'),
);

void main() {
  group('Task.fromJson', () {
    test('every field survives a round trip', () {
      final task = Task.fromJson(_full());
      expect(task.id, 't1');
      expect(task.teenId, 'teen');
      expect(task.parentId, 'parent');
      expect(task.kind, TaskKind.milestone);
      expect(task.title, 'School term');
      expect(task.description, 'Read the books');
      expect(task.reward, const Money.kzt(150050));
      expect(task.penalty, const Money.kzt(20000));
      expect(task.state, TaskState.submitted);
      expect(task.deadlineAt, DateTime.utc(2026, 11, 3, 18));
      expect(task.submittedAt, DateTime.utc(2026, 11, 2, 10, 30));
      expect(task.decidedAt, DateTime.utc(2026, 11, 2, 12));
      expect(task.decisionNote, 'Nice');
      expect(task.milestoneId, 'm1');
      expect(task.approvedTasks, 2);
      expect(task.totalTasks, 5);
      expect(task.isMilestone, isTrue);

      expect(task.toJson(), _wire(_full()));
      expect(Task.fromJson(task.toJson()), task);
    });

    test('omitted nullable fields stay null and stay omitted', () {
      final json = _full()
        ..remove('submittedAt')
        ..remove('decidedAt')
        ..remove('decisionNote')
        ..remove('milestoneId')
        ..remove('approvedTasks')
        ..remove('totalTasks')
        ..['kind'] = 'TASK'
        ..['state'] = 'ASSIGNED';
      final task = Task.fromJson(json);
      expect(task.submittedAt, isNull);
      expect(task.decidedAt, isNull);
      expect(task.decisionNote, isNull);
      expect(task.milestoneId, isNull);
      expect(task.approvedTasks, isNull);
      expect(task.totalTasks, isNull);
      expect(task.isMilestone, isFalse);
      expect(task.toJson(), _wire(json));
    });

    test('a missing description is an empty string', () {
      final task = Task.fromJson(_full()..remove('description'));
      expect(task.description, '');
    });

    test('explicit nulls are treated like omitted fields', () {
      final task = Task.fromJson(_full()..['milestoneId'] = null);
      expect(task.milestoneId, isNull);
    });

    test('an unknown state fails loudly', () {
      expect(
        () => Task.fromJson(_full()..['state'] = 'PAUSED'),
        _invalidResponse(),
      );
    });

    test('an unknown kind fails loudly', () {
      expect(
        () => Task.fromJson(_full()..['kind'] = 'GOAL'),
        _invalidResponse(),
      );
    });

    test('a foreign currency fails loudly', () {
      expect(
        () => Task.fromJson(_full()..['currency'] = 'USD'),
        _invalidResponse(),
      );
    });

    test('money must be whole minor units', () {
      expect(
        () => Task.fromJson(_full()..['rewardAmount'] = '1500'),
        _invalidResponse(),
      );
      expect(
        () => Task.fromJson(_full()..['penaltyAmount'] = 1.5),
        _invalidResponse(),
      );
    });

    test('a required field of the wrong type fails loudly', () {
      expect(() => Task.fromJson(_full()..['id'] = 1), _invalidResponse());
      expect(() => Task.fromJson(_full()..remove('title')), _invalidResponse());
      expect(
        () => Task.fromJson(_full()..['deadlineAt'] = 'tomorrow'),
        _invalidResponse(),
      );
      expect(
        () => Task.fromJson(_full()..remove('deadlineAt')),
        _invalidResponse(),
      );
    });

    test('an optional field of the wrong type fails loudly', () {
      expect(
        () => Task.fromJson(_full()..['approvedTasks'] = '2'),
        _invalidResponse(),
      );
      expect(
        () => Task.fromJson(_full()..['submittedAt'] = 5),
        _invalidResponse(),
      );
    });
  });

  group('enums', () {
    test('every state and kind maps back from its wire value', () {
      for (final state in TaskState.values) {
        expect(TaskState.fromWire(state.wire), state);
      }
      for (final kind in TaskKind.values) {
        expect(TaskKind.fromWire(kind.wire), kind);
      }
    });

    test('wire values are case-sensitive and null is rejected', () {
      expect(() => TaskState.fromWire('assigned'), _invalidResponse());
      expect(() => TaskState.fromWire(null), _invalidResponse());
      expect(() => TaskKind.fromWire(null), _invalidResponse());
    });

    test('only ASSIGNED and SUBMITTED are open', () {
      expect(TaskState.values.where((s) => s.isOpen), [
        TaskState.assigned,
        TaskState.submitted,
      ]);
    });
  });

  group('Proof.fromJson', () {
    test('an image proof', () {
      final proof = Proof.fromJson({
        'attemptNo': 2,
        'imageUrl': 'https://s3.test/p?X-Amz-Signature=abc',
        'createdAt': '2026-11-02T10:30:00Z',
      });
      expect(proof.attemptNo, 2);
      expect(proof.imageUrl, 'https://s3.test/p?X-Amz-Signature=abc');
      expect(proof.text, isNull);
      expect(proof.createdAt, DateTime.utc(2026, 11, 2, 10, 30));
      expect(Proof.fromJson(proof.toJson()), proof);
    });

    test('a text proof', () {
      final proof = Proof.fromJson({
        'attemptNo': 1,
        'imageUrl': null,
        'text': 'Done',
        'createdAt': '2026-11-02T10:30:00Z',
      });
      expect(proof.text, 'Done');
      expect(proof.imageUrl, isNull);
    });
  });
}
