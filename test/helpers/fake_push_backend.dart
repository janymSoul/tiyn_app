import 'dart:async';

import 'package:tiyn_app/features/push/data/device_repository.dart';
import 'package:tiyn_app/features/push/data/push_store.dart';

class FakePushStore implements PushStore {
  DeviceRecord? registration;
  bool pendingDelete = false;

  @override
  Future<DeviceRecord?> readRegistration() async => registration;

  @override
  Future<void> writeRegistration(DeviceRecord record) async =>
      registration = record;

  @override
  Future<void> clearRegistration() async => registration = null;

  @override
  Future<bool> hasPendingTokenDelete() async => pendingDelete;

  @override
  Future<void> markPendingTokenDelete() async => pendingDelete = true;

  @override
  Future<void> clearPendingTokenDelete() async => pendingDelete = false;
}

class FakeDeviceRepository implements DeviceRepository {
  final registered = <({String token, String locale})>[];
  final unregistered = <({String token, String authToken})>[];

  Object? registerError;

  /// When set, [unregister] waits for it (a DELETE that hangs).
  Completer<void>? unregisterBlocker;
  Object? unregisterError;

  @override
  Future<void> register({required String token, required String locale}) async {
    final error = registerError;
    if (error != null) throw error;
    registered.add((token: token, locale: locale));
  }

  @override
  Future<void> unregister({
    required String token,
    required String authToken,
  }) async {
    unregistered.add((token: token, authToken: authToken));
    await unregisterBlocker?.future;
    final error = unregisterError;
    if (error != null) throw error;
  }
}
