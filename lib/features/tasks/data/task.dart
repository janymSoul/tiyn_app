import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/network/json.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

part 'task.freezed.dart';

/// `TaskResponse` from `GET /tasks`. Decoded by hand because the amounts are
/// two fields (`rewardAmount` + `currency`) that become one [Money].
///
/// A milestone is a task with `kind == milestone`; the tasks under it point at
/// it through [milestoneId]. [approvedTasks] and [totalTasks] only come with
/// `GET /tasks/{id}`.
@freezed
abstract class Task with _$Task {
  const factory Task({
    required String id,
    required String teenId,
    required String parentId,
    required TaskKind kind,
    required String title,
    @Default('') String description,
    required Money reward,
    required Money penalty,
    required TaskState state,
    required DateTime deadlineAt,
    DateTime? submittedAt,
    DateTime? decidedAt,
    String? decisionNote,
    String? milestoneId,
    int? approvedTasks,
    int? totalTasks,
  }) = _Task;

  factory Task.fromJson(Map<String, Object?> json) {
    final currency = json['currency'];
    return Task(
      id: reqString(json, 'id'),
      teenId: reqString(json, 'teenId'),
      parentId: reqString(json, 'parentId'),
      kind: TaskKind.fromWire(json['kind']),
      title: reqString(json, 'title'),
      description: optString(json, 'description') ?? '',
      reward: Money.fromJson(json['rewardAmount'], currency),
      penalty: Money.fromJson(json['penaltyAmount'], currency),
      state: TaskState.fromWire(json['state']),
      deadlineAt: reqTime(json, 'deadlineAt'),
      submittedAt: optTime(json, 'submittedAt'),
      decidedAt: optTime(json, 'decidedAt'),
      decisionNote: optString(json, 'decisionNote'),
      milestoneId: optString(json, 'milestoneId'),
      approvedTasks: optInt(json, 'approvedTasks'),
      totalTasks: optInt(json, 'totalTasks'),
    );
  }
}

extension TaskJson on Task {
  /// The wire shape. Null fields are omitted, as the backend does.
  Map<String, Object?> toJson() => {
    'id': id,
    'teenId': teenId,
    'parentId': parentId,
    'kind': kind.wire,
    'title': title,
    'description': description,
    'rewardAmount': reward.minor,
    'penaltyAmount': penalty.minor,
    'currency': reward.currency,
    'state': state.wire,
    'deadlineAt': deadlineAt.toUtc().toIso8601String(),
    'submittedAt': ?submittedAt?.toUtc().toIso8601String(),
    'decidedAt': ?decidedAt?.toUtc().toIso8601String(),
    'decisionNote': ?decisionNote,
    'milestoneId': ?milestoneId,
    'approvedTasks': ?approvedTasks,
    'totalTasks': ?totalTasks,
  };

  bool get isMilestone => kind == TaskKind.milestone;
}
