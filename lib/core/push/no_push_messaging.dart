import 'package:tiyn_app/core/push/push_messaging.dart';

/// Push switched off: the default in tests and the stand-in when nothing
/// else is wired.
class NoPushMessaging implements PushMessaging {
  const NoPushMessaging();

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Future<void> deleteToken() async {}

  @override
  Future<PushPermission> permissionStatus() async => PushPermission.denied;

  @override
  Future<PushPermission> requestPermission() async => PushPermission.denied;

  @override
  Stream<PushMessage> get onForegroundMessage => const Stream.empty();

  @override
  Stream<PushMessage> get onOpenedMessage => const Stream.empty();

  @override
  Future<PushMessage?> initialMessage() async => null;
}
