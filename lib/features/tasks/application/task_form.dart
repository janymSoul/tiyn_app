import 'package:flutter/foundation.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/features/tasks/data/new_task.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';

/// Backend defaults: reward and penalty are at most 100 000 ₸.
const maxTaskAmount = Money.kzt(10000000);
const maxTitleLength = 200;

enum TaskField { title, reward, penalty, deadline, form }

enum TaskFormError {
  titleRequired,
  titleTooLong,
  amountInvalid,
  rewardRange,
  penaltyRange,
  deadlinePast,
  deadlineAfterMilestone,
}

@immutable
class TaskFormInput {
  const TaskFormInput({
    required this.teenId,
    this.kind = TaskKind.task,
    this.title = '',
    this.description = '',
    this.reward = '',
    this.penalty = '',
    required this.deadlineAt,
    this.milestoneId,
    this.milestoneDeadline,
  });

  final String teenId;
  final TaskKind kind;
  final String title;
  final String description;

  /// Raw text from the fields, parsed by [validateTask].
  final String reward;
  final String penalty;
  final DateTime deadlineAt;
  final String? milestoneId;

  /// Latest allowed deadline when the task goes under a milestone.
  final DateTime? milestoneDeadline;
}

@immutable
class TaskValidation {
  const TaskValidation(this.errors, this.task);

  final Map<TaskField, TaskFormError> errors;

  /// Set only when [errors] is empty.
  final NewTask? task;

  bool get isValid => errors.isEmpty;
}

/// Mirrors the backend's rules, so the common mistakes are caught before a
/// request. The server stays the authority: its answers are mapped too.
TaskValidation validateTask(TaskFormInput input, {required DateTime now}) {
  final errors = <TaskField, TaskFormError>{};

  final title = input.title.trim();
  if (title.isEmpty) {
    errors[TaskField.title] = TaskFormError.titleRequired;
  } else if (title.length > maxTitleLength) {
    errors[TaskField.title] = TaskFormError.titleTooLong;
  }

  final reward = Money.parseTenge(input.reward);
  if (reward == null) {
    errors[TaskField.reward] = TaskFormError.amountInvalid;
  } else if (reward.minor <= 0 || reward.minor > maxTaskAmount.minor) {
    errors[TaskField.reward] = TaskFormError.rewardRange;
  }

  var penalty = Money.zero;
  if (input.kind == TaskKind.task && input.penalty.trim().isNotEmpty) {
    final parsed = Money.parseTenge(input.penalty);
    if (parsed == null) {
      errors[TaskField.penalty] = TaskFormError.amountInvalid;
    } else if (parsed.minor > maxTaskAmount.minor) {
      errors[TaskField.penalty] = TaskFormError.penaltyRange;
    } else {
      penalty = parsed;
    }
  }

  if (!input.deadlineAt.isAfter(now)) {
    errors[TaskField.deadline] = TaskFormError.deadlinePast;
  } else if (input.milestoneDeadline != null &&
      input.deadlineAt.isAfter(input.milestoneDeadline!)) {
    errors[TaskField.deadline] = TaskFormError.deadlineAfterMilestone;
  }

  if (errors.isNotEmpty) return TaskValidation(errors, null);
  return TaskValidation(
    const {},
    NewTask(
      teenId: input.teenId,
      kind: input.kind,
      title: title,
      description: input.description.trim(),
      reward: reward!,
      penalty: penalty,
      deadlineAt: input.deadlineAt,
      milestoneId: input.milestoneId,
    ),
  );
}

/// The default deadline: tomorrow at 18:00 local.
DateTime defaultDeadline(DateTime now) =>
    DateTime(now.year, now.month, now.day + 1, 18);

/// Server error code → the field it is about (or the form).
TaskField fieldForServerCode(String code) => switch (code) {
  'invalid_title' => TaskField.title,
  'invalid_reward' => TaskField.reward,
  'invalid_penalty' => TaskField.penalty,
  'invalid_deadline' => TaskField.deadline,
  _ => TaskField.form,
};
