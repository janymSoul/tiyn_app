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

/// The teen's open cash-out request as `GET /dashboard` sends it. Every field
/// is required: a malformed one fails the whole dashboard loudly.
@freezed
abstract class OpenPayout with _$OpenPayout {
  const factory OpenPayout({
    required String id,
    required String parentId,
    required Money amount,
    required DateTime requestedAt,
    required DateTime expiresAt,
  }) = _OpenPayout;

  factory OpenPayout.fromJson(Map<String, Object?> json) {
    final currency = json['currency'];
    return OpenPayout(
      id: reqString(json, 'id'),
      parentId: reqString(json, 'parentId'),
      amount: Money.fromJson(json['amount'], currency),
      requestedAt: reqTime(json, 'requestedAt'),
      expiresAt: reqTime(json, 'expiresAt'),
    );
  }
}

/// The teen home in one call. Goals are in the response too, but nothing
/// shows them yet, so they are not decoded.
@freezed
abstract class Dashboard with _$Dashboard {
  const factory Dashboard({
    required Balance balance,
    required Money pending,
    required List<DashboardTask> chores,
    required List<DashboardTask> milestones,
    OpenPayout? openPayout,
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
      openPayout: json['openPayout'] == null
          ? null
          : OpenPayout.fromJson(asMap(json['openPayout'])),
    );
  }
}
