import 'dart:async';

import 'package:tiyn_app/core/push/push_messaging.dart';

class FakePushMessaging implements PushMessaging {
  FakePushMessaging({
    this.tokenValue = 'fcm-token-1',
    this.permission = PushPermission.granted,
  });

  String? tokenValue;
  PushPermission permission;
  PushPermission permissionAfterRequest = PushPermission.granted;
  PushMessage? initial;

  int tokenCalls = 0;
  int deleteTokenCalls = 0;
  int requestPermissionCalls = 0;
  Object? deleteTokenError;

  /// When set, [deleteToken] waits for it.
  Completer<void>? deleteTokenBlocker;

  final _refresh = StreamController<String>.broadcast();
  final _foreground = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<PushMessage>.broadcast();

  void emitTokenRefresh(String token) {
    tokenValue = token;
    _refresh.add(token);
  }

  void emitForeground(PushMessage message) => _foreground.add(message);

  void emitOpened(PushMessage message) => _opened.add(message);

  @override
  Future<String?> token() async {
    tokenCalls++;
    return tokenValue;
  }

  @override
  Stream<String> get onTokenRefresh => _refresh.stream;

  @override
  Future<void> deleteToken() async {
    deleteTokenCalls++;
    await deleteTokenBlocker?.future;
    final error = deleteTokenError;
    if (error != null) throw error;
    tokenValue = null;
  }

  @override
  Future<PushPermission> permissionStatus() async => permission;

  @override
  Future<PushPermission> requestPermission() async {
    requestPermissionCalls++;
    return permission = permissionAfterRequest;
  }

  @override
  Stream<PushMessage> get onForegroundMessage => _foreground.stream;

  @override
  Stream<PushMessage> get onOpenedMessage => _opened.stream;

  @override
  Future<PushMessage?> initialMessage() async => initial;
}
