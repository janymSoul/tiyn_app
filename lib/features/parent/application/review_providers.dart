import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/features/tasks/application/task_providers.dart';
import 'package:tiyn_app/features/tasks/data/proof.dart';
import 'package:tiyn_app/features/tasks/data/task.dart';

/// One task, loaded on its own so the review screen shows the latest state
/// even when the list it was opened from is stale. No automatic retries: the
/// screen has its own "Try again".
final taskDetailProvider = FutureProvider.autoDispose.family<Task, String>(
  (ref, id) => ref.watch(taskRepositoryProvider).get(id),
  retry: (_, _) => null,
);

/// Proofs carry presigned image URLs that die after about ten minutes, so
/// they are never kept: the provider is dropped when the screen closes.
final proofsProvider = FutureProvider.autoDispose.family<List<Proof>, String>(
  (ref, id) => ref.watch(taskRepositoryProvider).proofs(id),
  retry: (_, _) => null,
);

/// Oldest submission first, as the review queue.
List<Task> reviewQueue(Iterable<Task> submitted) {
  final queue = submitted.toList()
    ..sort((a, b) {
      final x = a.submittedAt;
      final y = b.submittedAt;
      if (x == null && y == null) return a.id.compareTo(b.id);
      if (x == null) return 1;
      if (y == null) return -1;
      final c = x.compareTo(y);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  return queue;
}
