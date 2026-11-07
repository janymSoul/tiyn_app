import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/tasks/application/task_providers.dart';
import 'package:tiyn_app/features/tasks/data/task.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';
import 'package:tiyn_app/features/tasks/data/task_repository.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

class _TestAuth extends AuthController {
  @override
  Future<User?> build() async => const User(
    id: 'p1',
    role: Role.parent,
    displayName: 'P',
    joinCode: 'ABCDEF',
  );

  void setUser(User? user) => state = AsyncData(user);
}

class _Repository implements TaskRepository {
  final queries = <({String? teenId, TaskState? state})>[];
  bool failing = false;
  int version = 0;

  @override
  Future<List<Task>> list({String? teenId, TaskState? state}) async {
    queries.add((teenId: teenId, state: state));
    if (failing) throw const ApiException(code: 'network_error');
    version++;
    return [
      Task(
        id: 'v$version',
        teenId: 'teen',
        parentId: 'p1',
        kind: TaskKind.task,
        title: 'T',
        reward: Money.zero,
        penalty: Money.zero,
        state: state ?? TaskState.assigned,
        deadlineAt: DateTime.utc(2026, 11, 3),
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late _Repository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _Repository();
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        authControllerProvider.overrideWith(_TestAuth.new),
        taskRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
  });

  const submitted = TaskQuery.inState(TaskState.submitted);

  Future<List<Task>> load(TaskQuery query) async {
    container.listen(taskListProvider(query), (_, _) {});
    await container.read(authControllerProvider.future);
    return container.read(taskListProvider(query).future);
  }

  test('the query decides the request', () async {
    await load(submitted);
    await load(const TaskQuery.forTeen('teen-9'));
    expect(repository.queries, [
      (teenId: null, state: TaskState.submitted),
      (teenId: 'teen-9', state: null),
    ]);
  });

  test('equal queries share one provider and one request', () async {
    await load(const TaskQuery.inState(TaskState.assigned));
    await load(const TaskQuery.inState(TaskState.assigned));
    expect(repository.queries, hasLength(1));
  });

  test('refresh replaces the list without going back to loading', () async {
    await load(submitted);
    final states = <bool>[];
    container.listen(taskListProvider(submitted), (_, next) {
      states.add(next.isLoading);
    });
    await container.read(taskListProvider(submitted).notifier).refresh();
    expect(container.read(taskListProvider(submitted)).value!.single.id, 'v2');
    expect(states, everyElement(isFalse));
  });

  test('a failed refresh keeps the list on screen', () async {
    await load(submitted);
    repository.failing = true;
    await container.read(taskListProvider(submitted).notifier).refresh();
    final state = container.read(taskListProvider(submitted));
    expect(state.hasError, isFalse);
    expect(state.value!.single.id, 'v1');
  });

  test('a failed first load is an error, and refresh surfaces it', () async {
    repository.failing = true;
    container.listen(taskListProvider(submitted), (_, _) {});
    await container.read(authControllerProvider.future);
    await expectLater(
      container.read(taskListProvider(submitted).future),
      throwsA(isA<ApiException>()),
    );
    await container.read(taskListProvider(submitted).notifier).refresh();
    expect(container.read(taskListProvider(submitted)).hasError, isTrue);
  });

  test('signing out empties the list without a request', () async {
    await load(submitted);
    (container.read(authControllerProvider.notifier) as _TestAuth).setUser(
      null,
    );
    expect(await container.read(taskListProvider(submitted).future), isEmpty);
    expect(repository.queries, hasLength(1));
  });
}
