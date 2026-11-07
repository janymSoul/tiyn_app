import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/app/providers.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/tasks/application/proof_upload.dart';
import 'package:tiyn_app/features/tasks/data/task.dart';
import 'package:tiyn_app/features/tasks/data/task_repository.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(apiClientProvider)),
);

/// What a list asks the backend for. Equality makes it a provider family key.
@immutable
class TaskQuery {
  const TaskQuery({this.teenId, this.state});

  /// Every `ASSIGNED` or `SUBMITTED` task is one cheap call each; the full
  /// history (no [state]) is only for a teen's own detail screen.
  const TaskQuery.inState(TaskState this.state) : teenId = null;
  const TaskQuery.forTeen(String this.teenId) : state = null;

  final String? teenId;
  final TaskState? state;

  @override
  bool operator ==(Object other) =>
      other is TaskQuery && other.teenId == teenId && other.state == state;

  @override
  int get hashCode => Object.hash(teenId, state);
}

class TaskListController extends AsyncNotifier<List<Task>> {
  TaskListController(this.query);

  final TaskQuery query;

  @override
  Future<List<Task>> build() async {
    // A different user must never see the previous user's tasks.
    if (ref.watch(currentUserIdProvider) == null) return const [];
    return _fetch();
  }

  Future<List<Task>> _fetch() => ref
      .read(taskRepositoryProvider)
      .list(teenId: query.teenId, state: query.state);

  /// Reloads without a spinner. If it fails while a list is already on
  /// screen, that list stays and nothing is surfaced.
  Future<void> refresh() async {
    final previous = state.value;
    final next = await AsyncValue.guard(_fetch);
    if (!ref.mounted) return;
    if (next.hasError && previous != null) return;
    state = next;
  }
}

final taskListProvider =
    AsyncNotifierProvider.family<TaskListController, List<Task>, TaskQuery>(
      TaskListController.new,
    );

final photoPickerProvider = Provider<PhotoPicker>(
  (_) => ImagePickerPhotoPicker(),
);

final photoEncoderProvider = Provider<PhotoEncoder>(
  (_) => FlutterPhotoEncoder(),
);
