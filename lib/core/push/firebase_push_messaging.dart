// The backend sends to classic FCM registration tokens (Admin SDK), which
// getToken/onTokenRefresh/deleteToken return. The newer register() API hands
// out Firebase Installation IDs for direct send, a different target.
// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:tiyn_app/core/push/firebase_init.dart';
import 'package:tiyn_app/core/push/push_messaging.dart';

/// The real service. Firebase may have failed to start (no Google Play
/// services); every call then answers "unavailable" and retries the start, so
/// a phone that gets Play services later begins to work without a reinstall.
class FirebasePushMessaging implements PushMessaging {
  FirebasePushMessaging({required bool initialized}) : _ready = initialized {
    if (_ready) _attach();
  }

  bool _ready;
  FirebaseMessaging? _messaging;

  final _refresh = StreamController<String>.broadcast();
  final _foreground = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<PushMessage>.broadcast();

  FirebaseMessaging? get _fcm => _messaging;

  Future<bool> _ensure() async {
    if (!_ready) {
      _ready = await initFirebase();
      if (_ready) _attach();
    }
    return _ready;
  }

  void _attach() {
    final fcm = _messaging = FirebaseMessaging.instance;
    fcm.onTokenRefresh.listen(_refresh.add, onError: _ignore);
    FirebaseMessaging.onMessage
        .map(_convert)
        .listen(_foreground.add, onError: _ignore);
    FirebaseMessaging.onMessageOpenedApp
        .map(_convert)
        .listen(_opened.add, onError: _ignore);
  }

  static void _ignore(Object _) {}

  static PushMessage _convert(RemoteMessage m) => PushMessage(
    title: m.notification?.title,
    body: m.notification?.body,
    data: {for (final e in m.data.entries) e.key: '${e.value}'},
  );

  static PushPermission _permission(AuthorizationStatus status) =>
      switch (status) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional => PushPermission.granted,
        AuthorizationStatus.denied ||
        AuthorizationStatus.deniedPermanently => PushPermission.denied,
        AuthorizationStatus.notDetermined => PushPermission.notDetermined,
      };

  Future<T> _guard<T>(
    Future<T> Function(FirebaseMessaging) call,
    T fallback,
  ) async {
    if (!await _ensure()) return fallback;
    try {
      return await call(_fcm!);
    } on Object catch (e) {
      debugPrint('Push call failed: ${e.runtimeType}');
      return fallback;
    }
  }

  @override
  Future<String?> token() => _guard((f) => f.getToken(), null);

  @override
  Stream<String> get onTokenRefresh => _refresh.stream;

  @override
  Future<void> deleteToken() async {
    if (!await _ensure()) return;
    await _fcm!.deleteToken();
  }

  @override
  Future<PushPermission> permissionStatus() => _guard(
    (f) async =>
        _permission((await f.getNotificationSettings()).authorizationStatus),
    PushPermission.denied,
  );

  @override
  Future<PushPermission> requestPermission() => _guard(
    (f) async => _permission((await f.requestPermission()).authorizationStatus),
    PushPermission.denied,
  );

  @override
  Stream<PushMessage> get onForegroundMessage => _foreground.stream;

  @override
  Stream<PushMessage> get onOpenedMessage => _opened.stream;

  @override
  Future<PushMessage?> initialMessage() => _guard((f) async {
    final m = await f.getInitialMessage();
    return m == null ? null : _convert(m);
  }, null);
}
