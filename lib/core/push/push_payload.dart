import 'package:tiyn_app/core/push/push_type.dart';

/// The `data` map of a push, read tolerantly: anything missing, blank or
/// unknown becomes null instead of an error.
class PushPayload {
  const PushPayload({this.type, this.taskId, this.payoutId});

  factory PushPayload.fromData(Map<String, String> data) => PushPayload(
    type: PushType.fromWire(data['type']?.trim()),
    taskId: _id(data['taskId']),
    payoutId: _id(data['payoutId']),
  );

  final PushType? type;
  final String? taskId;
  final String? payoutId;

  static String? _id(String? raw) {
    final id = raw?.trim();
    return id == null || id.isEmpty ? null : id;
  }
}
