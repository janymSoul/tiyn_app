import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/features/tasks/data/task.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';
import 'package:tiyn_app/features/tasks/data/task_repository.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

Task fakeTask({
  String id = 't1',
  String teenId = 'teen1',
  TaskKind kind = TaskKind.task,
  TaskState state = TaskState.assigned,
  String title = 'Wash dishes',
  Money? reward,
  DateTime? deadlineAt,
  String? milestoneId,
  int? approvedTasks,
  int? totalTasks,
}) => Task(
  id: id,
  teenId: teenId,
  parentId: 'parent1',
  kind: kind,
  title: title,
  reward: reward ?? const Money.kzt(150000),
  penalty: Money.zero,
  state: state,
  deadlineAt: deadlineAt ?? DateTime.utc(2026, 11, 20, 13),
  milestoneId: milestoneId,
  approvedTasks: approvedTasks,
  totalTasks: totalTasks,
);

/// Serves `list` from [tasks] and records every request, so a test can assert
/// exactly which calls a screen made.
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository([List<Task> tasks = const []]) : tasks = List.of(tasks);

  List<Task> tasks;
  Object? error;
  final requests = <({String? teenId, TaskState? state})>[];

  int get calls => requests.length;

  int callsFor(TaskState? state) =>
      requests.where((r) => r.state == state).length;

  @override
  Future<List<Task>> list({String? teenId, TaskState? state}) async {
    requests.add((teenId: teenId, state: state));
    final failure = error;
    if (failure != null) throw failure;
    return [
      for (final t in tasks)
        if ((teenId == null || t.teenId == teenId) &&
            (state == null || t.state == state))
          t,
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
