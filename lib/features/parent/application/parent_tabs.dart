import 'package:tiyn_app/features/tasks/application/task_providers.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

/// Order matches the branches of the parent shell.
enum ParentTab { home, review }

/// Waiting for the parent's decision: the "To check" tab, its badge and the
/// "N to check" line on the home screen all read this one list.
final submittedTasksProvider = taskListProvider(
  const TaskQuery.inState(TaskState.submitted),
);

/// Open work the teen still has to do, for the "N active" line.
final assignedTasksProvider = taskListProvider(
  const TaskQuery.inState(TaskState.assigned),
);
