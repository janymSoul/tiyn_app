import 'package:tiyn_app/core/network/idempotent_submit_controller.dart';
import 'package:tiyn_app/features/tasks/data/new_task.dart';
import 'package:tiyn_app/features/tasks/data/task.dart';

/// Creating a task: the key rules are in [IdempotentSubmitController].
class CreateTaskController extends IdempotentSubmitController<NewTask, Task> {
  CreateTaskController({required super.send, super.newKey});
}
