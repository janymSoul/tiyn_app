import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/features/tasks/application/task_providers.dart';
import 'package:tiyn_app/features/tasks/data/task.dart';

class TaskDetailController extends AsyncNotifier<Task> {
  TaskDetailController(this.id);

  final String id;

  @override
  Future<Task> build() => _fetch();

  Future<Task> _fetch() => ref.read(taskRepositoryProvider).get(id);

  /// Reloads without a spinner. If it fails while a task is already on
  /// screen, that task stays and nothing is surfaced.
  Future<void> refresh() async {
    final previous = state.value;
    final next = await AsyncValue.guard(_fetch);
    if (!ref.mounted) return;
    if (next.hasError && previous != null) return;
    state = next;
  }
}

/// One task, loaded on its own so a detail screen shows the latest state even
/// when the list it was opened from is stale. No automatic retries: the screen
/// has its own "Try again".
final taskDetailProvider = AsyncNotifierProvider.autoDispose
    .family<TaskDetailController, Task, String>(
      TaskDetailController.new,
      retry: (_, _) => null,
    );
