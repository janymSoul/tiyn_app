import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// What was last sent to `PUT /devices`.
@immutable
class DeviceRecord {
  const DeviceRecord({
    required this.userId,
    required this.token,
    required this.locale,
  });

  final String userId;
  final String token;
  final String locale;

  @override
  bool operator ==(Object other) =>
      other is DeviceRecord &&
      other.userId == userId &&
      other.token == token &&
      other.locale == locale;

  @override
  int get hashCode => Object.hash(userId, token, locale);
}

/// Small push-related state that must survive a restart. Secure storage is
/// already a dependency; nothing here is large or hot.
class PushStore {
  PushStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _registrationKey = 'tiyn_push_registration';
  static const _pendingDeleteKey = 'tiyn_push_pending_delete';
  final FlutterSecureStorage _storage;

  Future<DeviceRecord?> readRegistration() async {
    final raw = await _storage.read(key: _registrationKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, Object?>;
      return DeviceRecord(
        userId: map['userId']! as String,
        token: map['token']! as String,
        locale: map['locale']! as String,
      );
    } on Object {
      return null;
    }
  }

  Future<void> writeRegistration(DeviceRecord record) => _storage.write(
    key: _registrationKey,
    value: jsonEncode({
      'userId': record.userId,
      'token': record.token,
      'locale': record.locale,
    }),
  );

  Future<void> clearRegistration() => _storage.delete(key: _registrationKey);

  /// Set when a sign-out started, cleared once the old FCM token is dead.
  Future<bool> hasPendingTokenDelete() async =>
      await _storage.read(key: _pendingDeleteKey) != null;

  Future<void> markPendingTokenDelete() =>
      _storage.write(key: _pendingDeleteKey, value: '1');

  Future<void> clearPendingTokenDelete() =>
      _storage.delete(key: _pendingDeleteKey);
}
