import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/json.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

part 'dashboard.freezed.dart';

/// A chore or milestone as `GET /dashboard` sends it: no teen, parent or
/// decision fields. [milestoneId] is optional on purpose: an older backend
/// does not send it, and the chore then simply stays ungrouped.
@freezed
abstract class DashboardTask with _$DashboardTask {
  const factory DashboardTask({
    required String id,
    required TaskKind kind,
    required String title,
    @Default('') String description,
    required Money reward,
    required Money penalty,
    required TaskState state,
    required DateTime deadlineAt,
    String? milestoneId,
    int? approvedTasks,
    int? totalTasks,
  }) = _DashboardTask;

  factory DashboardTask.fromJson(Map<String, Object?> json) {
    final currency = json['currency'];
    return DashboardTask(
      id: reqString(json, 'id'),
      kind: TaskKind.fromWire(json['kind']),
      title: reqString(json, 'title'),
      description: optString(json, 'description') ?? '',
      reward: Money.fromJson(json['rewardAmount'], currency),
      penalty: Money.fromJson(json['penaltyAmount'], currency),
      state: TaskState.fromWire(json['state']),
      deadlineAt: reqTime(json, 'deadlineAt'),
      milestoneId: optString(json, 'milestoneId'),
      approvedTasks: optInt(json, 'approvedTasks'),
      totalTasks: optInt(json, 'totalTasks'),
    );
  }
}

@freezed
abstract class Balance with _$Balance {
  const factory Balance({
    required Money balance,
    required Money locked,
    required Money available,
  }) = _Balance;

  factory Balance.fromJson(Map<String, Object?> json) {
    final currency = json['currency'];
    Money amount(String key) => Money.fromJson(json[key], currency);
    return Balance(
      balance: amount('balanceAmount'),
      locked: amount('lockedAmount'),
      available: amount('availableAmount'),
    );
  }
}

/// The teen home in one call. Goals and the open payout are in the response
/// too, but nothing in Phase 1 shows them, so they are not decoded.
@freezed
abstract class Dashboard with _$Dashboard {
  const factory Dashboard({
    required Balance balance,
    required Money pending,
    required List<DashboardTask> chores,
    required List<DashboardTask> milestones,
  }) = _Dashboard;

  factory Dashboard.fromJson(Map<String, Object?> json) {
    final balance = Balance.fromJson(asMap(json['balance']));
    List<DashboardTask> tasks(String key) => [
      for (final t in asList(json[key])) DashboardTask.fromJson(asMap(t)),
    ];
    final pending = json['pendingAmount'];
    if (pending is! int) throw const ApiException(code: 'invalid_response');
    return Dashboard(
      balance: balance,
      pending: Money(pending, balance.available.currency),
      chores: tasks('chores'),
      milestones: tasks('milestones'),
    );
  }
}
