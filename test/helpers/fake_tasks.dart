import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/network/idempotency_key.dart';
import 'package:tiyn_app/features/tasks/data/new_task.dart';
import 'package:tiyn_app/features/tasks/data/proof.dart';
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
  DateTime? submittedAt,
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
  submittedAt: submittedAt,
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

  /// Every `create`, with the key it was sent under.
  final created = <({NewTask task, IdempotencyKey key})>[];

  /// What `create` does; by default it succeeds.
  Future<Task> Function(NewTask task, IdempotencyKey key)? onCreate;

  @override
  Future<Task> create(NewTask task, {required IdempotencyKey key}) async {
    created.add((task: task, key: key));
    final handler = onCreate;
    if (handler != null) return handler(task, key);
    return fakeTask(
      id: 'new${created.length}',
      teenId: task.teenId,
      kind: task.kind,
      title: task.title,
      reward: task.reward,
      deadlineAt: task.deadlineAt,
      milestoneId: task.milestoneId,
    );
  }

  /// Proofs by task id, and how often they were asked for.
  final proofsById = <String, List<Proof>>{};
  int proofCalls = 0;
  int getCalls = 0;

  /// Every approve / reject / redo, in order.
  final decisions =
      <({String action, String id, String? note, DateTime? deadline})>[];

  /// Runs before a decision takes effect; throw to make it fail.
  Future<void> Function(String action, String id)? onDecision;

  @override
  Future<Task> get(String id) async {
    getCalls++;
    final failure = error;
    if (failure != null) throw failure;
    return tasks.firstWhere((t) => t.id == id);
  }

  @override
  Future<List<Proof>> proofs(String id) async {
    proofCalls++;
    return proofsById[id] ?? const [];
  }

  Future<Task> _decide(
    String action,
    String id,
    TaskState to, {
    String? note,
    DateTime? deadline,
  }) async {
    decisions.add((action: action, id: id, note: note, deadline: deadline));
    await onDecision?.call(action, id);
    final i = tasks.indexWhere((t) => t.id == id);
    tasks[i] = tasks[i].copyWith(state: to);
    return tasks[i];
  }

  @override
  Future<Task> cancel(String id) => _decide('cancel', id, TaskState.cancelled);

  @override
  Future<Task> approve(String id) => _decide('approve', id, TaskState.approved);

  @override
  Future<Task> reject(String id, {String? note}) =>
      _decide('reject', id, TaskState.rejected, note: note);

  @override
  Future<Task> requestRedo(String id, {String? note, DateTime? deadlineAt}) =>
      _decide('redo', id, TaskState.assigned, note: note, deadline: deadlineAt);

  /// Every proof sent, with the key it went under. `photo` is null for text.
  final submissions =
      <({String id, String? text, List<int>? photo, IdempotencyKey key})>[];

  /// Runs before a submit takes effect; throw to make it fail.
  Future<void> Function()? onSubmit;

  Future<Task> _submit(
    String id,
    String? text,
    List<int>? photo,
    IdempotencyKey key,
  ) async {
    submissions.add((id: id, text: text, photo: photo, key: key));
    await onSubmit?.call();
    final i = tasks.indexWhere((t) => t.id == id);
    tasks[i] = tasks[i].copyWith(state: TaskState.submitted);
    return tasks[i];
  }

  @override
  Future<Task> submitText(
    String id,
    String text, {
    required IdempotencyKey key,
  }) => _submit(id, text, null, key);

  @override
  Future<Task> submitPhoto(
    String id, {
    required List<int> bytes,
    required String filename,
    required String contentType,
    required IdempotencyKey key,
  }) => _submit(id, null, bytes, key);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
