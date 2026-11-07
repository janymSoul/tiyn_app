import 'package:flutter/foundation.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';

/// Body of `POST /tasks`. Validation lives with the form (P4); this only
/// puts the fields on the wire.
@immutable
class NewTask {
  const NewTask({
    required this.teenId,
    this.kind = TaskKind.task,
    required this.title,
    this.description = '',
    required this.reward,
    this.penalty = Money.zero,
    required this.deadlineAt,
    this.milestoneId,
  });

  final String teenId;
  final TaskKind kind;
  final String title;
  final String description;
  final Money reward;
  final Money penalty;
  final DateTime deadlineAt;
  final String? milestoneId;

  Map<String, Object?> toJson() => {
    'teenId': teenId,
    'kind': kind.wire,
    'title': title,
    'description': description,
    'rewardAmount': reward.minor,
    'penaltyAmount': penalty.minor,
    'currency': reward.currency,
    'deadlineAt': deadlineAt.toUtc().toIso8601String(),
    'milestoneId': ?milestoneId,
  };

  @override
  bool operator ==(Object other) =>
      other is NewTask &&
      other.teenId == teenId &&
      other.kind == kind &&
      other.title == title &&
      other.description == description &&
      other.reward == reward &&
      other.penalty == penalty &&
      other.deadlineAt == deadlineAt &&
      other.milestoneId == milestoneId;

  @override
  int get hashCode => Object.hash(
    teenId,
    kind,
    title,
    description,
    reward,
    penalty,
    deadlineAt,
    milestoneId,
  );
}
