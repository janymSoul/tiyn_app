import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';
import 'package:tiyn_app/features/teen/data/dashboard.dart';
import 'package:tiyn_app/features/teen/data/dashboard_repository.dart';

DashboardTask fakeChore({
  String id = 'c1',
  String title = 'Wash dishes',
  TaskKind kind = TaskKind.task,
  TaskState state = TaskState.assigned,
  Money? reward,
  DateTime? deadlineAt,
  String? milestoneId,
  int? approvedTasks,
  int? totalTasks,
}) => DashboardTask(
  id: id,
  kind: kind,
  title: title,
  reward: reward ?? const Money.kzt(150000),
  penalty: Money.zero,
  state: state,
  deadlineAt: deadlineAt ?? DateTime.utc(2026, 12, 1, 13),
  milestoneId: milestoneId,
  approvedTasks: approvedTasks,
  totalTasks: totalTasks,
);

DashboardTask fakeMilestone({
  String id = 'm1',
  String title = 'School term',
  TaskState state = TaskState.assigned,
  int? approvedTasks,
  int? totalTasks,
}) => fakeChore(
  id: id,
  title: title,
  kind: TaskKind.milestone,
  state: state,
  reward: const Money.kzt(500000),
  approvedTasks: approvedTasks,
  totalTasks: totalTasks,
);

Dashboard fakeDashboard({
  Money balance = const Money.kzt(1500000),
  Money locked = const Money.kzt(200000),
  Money? available,
  Money pending = Money.zero,
  List<DashboardTask> chores = const [],
  List<DashboardTask> milestones = const [],
  OpenPayout? openPayout,
}) => Dashboard(
  balance: Balance(
    balance: balance,
    locked: locked,
    available: available ?? const Money.kzt(1250000),
  ),
  pending: pending,
  chores: chores,
  milestones: milestones,
  openPayout: openPayout,
);

class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository([Dashboard? dashboard])
    : dashboard = dashboard ?? fakeDashboard();

  Dashboard dashboard;
  Object? error;
  int calls = 0;

  @override
  Future<Dashboard> load() async {
    calls++;
    final failure = error;
    if (failure != null) throw failure;
    return dashboard;
  }
}
