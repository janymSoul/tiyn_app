import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens this app's page in the system notification settings. Neither
/// Firebase package can, so it is a few lines of Kotlin in `MainActivity`.
abstract interface class NotificationSettingsOpener {
  Future<void> open();
}

class MethodChannelNotificationSettingsOpener
    implements NotificationSettingsOpener {
  const MethodChannelNotificationSettingsOpener();

  static const _channel = MethodChannel('kz.tiyn.app/notifications');

  @override
  Future<void> open() async {
    try {
      await _channel.invokeMethod<void>('openSettings');
    } on PlatformException catch (e) {
      debugPrint('Could not open notification settings: ${e.code}');
    } on MissingPluginException {
      debugPrint('Notification settings channel is not available');
    }
  }
}

class NoNotificationSettingsOpener implements NotificationSettingsOpener {
  const NoNotificationSettingsOpener();

  @override
  Future<void> open() async {}
}

/// Off by default so tests never touch the platform; `main` wires the real one.
final notificationSettingsOpenerProvider = Provider<NotificationSettingsOpener>(
  (_) => const NoNotificationSettingsOpener(),
);
