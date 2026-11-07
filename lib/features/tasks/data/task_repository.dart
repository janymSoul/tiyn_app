import 'package:tiyn_app/core/network/api_client.dart';
import 'package:tiyn_app/core/network/idempotency_key.dart';
import 'package:tiyn_app/core/network/json.dart';
import 'package:tiyn_app/features/tasks/data/new_task.dart';
import 'package:tiyn_app/features/tasks/data/proof.dart';
import 'package:tiyn_app/features/tasks/data/task.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

Task _task(Object? json) => Task.fromJson(asMap(json));

class TaskRepository {
  TaskRepository(this._api);

  final ApiClient _api;

  Future<List<Task>> list({String? teenId, TaskState? state}) => _api.get(
    '/tasks',
    query: {'teenId': ?teenId, 'state': ?state?.wire},
    decode: (json) => asList(json).map(_task).toList(),
  );

  Future<Task> get(String id) => _api.get('/tasks/$id', decode: _task);

  /// [key] must be the same for retries of the same payload. See ADR-0001.
  Future<Task> create(NewTask task, {required IdempotencyKey key}) => _api.post(
    '/tasks',
    body: task.toJson(),
    idempotencyKey: key,
    decode: _task,
  );

  Future<Task> cancel(String id) =>
      _api.post('/tasks/$id/cancel', decode: _task);

  Future<Task> approve(String id) =>
      _api.post('/tasks/$id/approve', decode: _task);

  Future<Task> reject(String id, {String? note}) =>
      _api.post('/tasks/$id/reject', body: _noteBody(note), decode: _task);

  Future<Task> requestRedo(String id, {String? note, DateTime? deadlineAt}) =>
      _api.post(
        '/tasks/$id/request-redo',
        body: {
          ..._noteBody(note) ?? const {},
          'deadlineAt': ?deadlineAt?.toUtc().toIso8601String(),
        },
        decode: _task,
      );

  Future<List<Proof>> proofs(String id) => _api.get(
    '/tasks/$id/proofs',
    decode: (json) =>
        asList(json).map((p) => Proof.fromJson(asMap(p))).toList(),
  );

  Future<Task> submitText(
    String id,
    String text, {
    required IdempotencyKey key,
  }) => _api.post(
    '/tasks/$id/submit',
    body: {'text': text},
    idempotencyKey: key,
    decode: _task,
  );

  Future<Task> submitPhoto(
    String id, {
    required List<int> bytes,
    required String filename,
    required String contentType,
    required IdempotencyKey key,
  }) => _api.postMultipart(
    '/tasks/$id/submit',
    bytes: bytes,
    filename: filename,
    contentType: contentType,
    idempotencyKey: key,
    decode: _task,
  );

  static Map<String, Object?>? _noteBody(String? note) {
    final trimmed = note?.trim();
    return trimmed == null || trimmed.isEmpty ? null : {'note': trimmed};
  }
}
