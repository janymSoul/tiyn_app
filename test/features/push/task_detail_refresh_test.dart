import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/features/tasks/application/task_detail_provider.dart';
import 'package:tiyn_app/features/tasks/application/task_providers.dart';

import '../../helpers/fake_tasks.dart';

void main() {
  test('a failed silent refresh keeps the task that is on screen', () async {
    final repo = FakeTaskRepository([fakeTask(id: 't1', title: 'Wash dishes')]);
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [taskRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final provider = taskDetailProvider('t1');
    container.listen(provider, (_, _) {});
    await container.read(provider.future);

    repo.error = const ApiException(code: 'network_error');
    await container.read(provider.notifier).refresh();

    expect(container.read(provider).value?.title, 'Wash dishes');
    expect(container.read(provider).hasError, isFalse);
  });

  test('a successful silent refresh shows the new state', () async {
    final repo = FakeTaskRepository([fakeTask(id: 't1', title: 'Old')]);
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [taskRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final provider = taskDetailProvider('t1');
    container.listen(provider, (_, _) {});
    await container.read(provider.future);

    repo.tasks = [fakeTask(id: 't1', title: 'New')];
    await container.read(provider.notifier).refresh();

    expect(container.read(provider).value?.title, 'New');
  });
}
