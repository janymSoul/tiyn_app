import 'package:uuid/uuid.dart';

/// One key per user action. Reuse the same key when retrying the *same* payload;
/// create a new one when the payload changes or the action succeeded.
extension type const IdempotencyKey(String value) {
  factory IdempotencyKey.generate() => IdempotencyKey(const Uuid().v4());
}
