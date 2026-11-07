import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/features/tasks/application/task_form.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';

final _now = DateTime.utc(2026, 11, 7, 9);
final _tomorrow = DateTime.utc(2026, 11, 8, 13);

TaskFormInput _input({
  String title = 'Wash dishes',
  String reward = '1 500',
  String penalty = '',
  String description = '',
  DateTime? deadline,
  TaskKind kind = TaskKind.task,
  String? milestoneId,
  DateTime? milestoneDeadline,
}) => TaskFormInput(
  teenId: 'teen',
  kind: kind,
  title: title,
  description: description,
  reward: reward,
  penalty: penalty,
  deadlineAt: deadline ?? _tomorrow,
  milestoneId: milestoneId,
  milestoneDeadline: milestoneDeadline,
);

void main() {
  group('validateTask', () {
    test('a good form becomes a request body', () {
      final v = validateTask(
        _input(title: '  Wash dishes  ', description: ' all ', penalty: '200'),
        now: _now,
      );
      expect(v.isValid, isTrue);
      final t = v.task!;
      expect(t.title, 'Wash dishes', reason: 'trimmed');
      expect(t.description, 'all');
      expect(t.reward, const Money.kzt(150000));
      expect(t.penalty, const Money.kzt(20000));
      expect(t.deadlineAt, _tomorrow);
      expect(t.teenId, 'teen');
    });

    test('title: required, trimmed, at most 200', () {
      TaskFormError? err(String t) =>
          validateTask(_input(title: t), now: _now).errors[TaskField.title];
      expect(err(''), TaskFormError.titleRequired);
      expect(err('   '), TaskFormError.titleRequired);
      expect(err('a' * 200), isNull);
      expect(err('a' * 201), TaskFormError.titleTooLong);
      expect(err('  ${'a' * 200}  '), isNull, reason: 'length is after trim');
    });

    test('reward: a number above 0 and at most 100 000 ₸', () {
      TaskFormError? err(String r) =>
          validateTask(_input(reward: r), now: _now).errors[TaskField.reward];
      expect(err(''), TaskFormError.amountInvalid);
      expect(err('abc'), TaskFormError.amountInvalid);
      expect(err('1.234'), TaskFormError.amountInvalid);
      expect(err('0'), TaskFormError.rewardRange);
      expect(err('0,00'), TaskFormError.rewardRange);
      expect(err('0,01'), isNull);
      expect(err('100 000'), isNull);
      expect(err('100 000,01'), TaskFormError.rewardRange);
      expect(err('99999999999999999999999'), isNotNull, reason: 'overflow');
    });

    test('penalty: optional, zero allowed, at most the maximum', () {
      TaskFormError? err(String p) =>
          validateTask(_input(penalty: p), now: _now).errors[TaskField.penalty];
      expect(err(''), isNull);
      expect(err('  '), isNull);
      expect(err('0'), isNull);
      expect(err('x'), TaskFormError.amountInvalid);
      expect(err('100 000'), isNull);
      expect(err('100 001'), TaskFormError.penaltyRange);
    });

    test('a blank penalty is sent as zero', () {
      final v = validateTask(_input(penalty: ''), now: _now);
      expect(v.task!.penalty, Money.zero);
    });

    test('a milestone has no penalty, whatever is typed', () {
      final v = validateTask(
        _input(kind: TaskKind.milestone, penalty: 'garbage'),
        now: _now,
      );
      expect(v.isValid, isTrue);
      expect(v.task!.penalty, Money.zero);
      expect(v.task!.kind, TaskKind.milestone);
    });

    test('deadline must be in the future', () {
      TaskFormError? err(DateTime d) => validateTask(
        _input(deadline: d),
        now: _now,
      ).errors[TaskField.deadline];
      expect(
        err(_now),
        TaskFormError.deadlinePast,
        reason: 'now is not future',
      );
      expect(
        err(_now.subtract(const Duration(minutes: 1))),
        TaskFormError.deadlinePast,
      );
      expect(err(_now.add(const Duration(seconds: 1))), isNull);
    });

    test('under a milestone the deadline cannot be later than its own', () {
      final limit = DateTime.utc(2026, 12, 1);
      TaskFormError? err(DateTime d) => validateTask(
        _input(deadline: d, milestoneId: 'm', milestoneDeadline: limit),
        now: _now,
      ).errors[TaskField.deadline];
      expect(err(limit), isNull, reason: 'equal is inside the bounds');
      expect(
        err(limit.add(const Duration(minutes: 1))),
        TaskFormError.deadlineAfterMilestone,
      );
    });

    test('the milestone id goes into the request', () {
      final v = validateTask(_input(milestoneId: 'm1'), now: _now);
      expect(v.task!.milestoneId, 'm1');
    });

    test('all errors are reported together', () {
      final v = validateTask(
        _input(title: '', reward: '', deadline: _now),
        now: _now,
      );
      expect(v.errors.keys.toSet(), {
        TaskField.title,
        TaskField.reward,
        TaskField.deadline,
      });
      expect(v.task, isNull);
    });
  });

  test('default deadline is tomorrow 18:00 local', () {
    final now = DateTime(2026, 11, 7, 21, 45);
    expect(defaultDeadline(now), DateTime(2026, 11, 8, 18));
    expect(
      defaultDeadline(DateTime(2026, 12, 31, 8)),
      DateTime(2027, 1, 1, 18),
    );
  });

  test('server codes map to their field, others to the form', () {
    expect(fieldForServerCode('invalid_title'), TaskField.title);
    expect(fieldForServerCode('invalid_reward'), TaskField.reward);
    expect(fieldForServerCode('invalid_penalty'), TaskField.penalty);
    expect(fieldForServerCode('invalid_deadline'), TaskField.deadline);
    expect(fieldForServerCode('invalid_milestone'), TaskField.form);
    expect(fieldForServerCode('teen_required'), TaskField.form);
    expect(fieldForServerCode('anything'), TaskField.form);
  });

  group('Money.parseTenge as the form uses it', () {
    test('spaces, commas and dots', () {
      expect(Money.parseTenge('1 500'), const Money.kzt(150000));
      expect(Money.parseTenge('1 500'), const Money.kzt(150000));
      expect(Money.parseTenge('1500,5'), const Money.kzt(150050));
      expect(Money.parseTenge('1500.50'), const Money.kzt(150050));
      expect(Money.parseTenge(' 7 '), const Money.kzt(700));
      expect(Money.parseTenge('-5'), isNull);
      expect(Money.parseTenge('1,2,3'), isNull);
    });
  });
}
