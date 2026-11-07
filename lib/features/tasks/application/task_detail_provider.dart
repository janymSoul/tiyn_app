import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/features/tasks/application/task_providers.dart';
import 'package:tiyn_app/features/tasks/data/task.dart';

/// One task, loaded on its own so a detail screen shows the latest state even
/// when the list it was opened from is stale. No automatic retries: the screen
/// has its own "Try again".
final taskDetailProvider = FutureProvider.autoDispose.family<Task, String>(
  (ref, id) => ref.watch(taskRepositoryProvider).get(id),
  retry: (_, _) => null,
);
