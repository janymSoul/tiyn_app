import 'package:tiyn_app/core/push/push_payload.dart';

/// What the app needs from the push service. Only `core/push` knows that
/// Firebase is behind it, so everything else is testable with a fake.
enum PushPermission { granted, denied, notDetermined }

/// A push as the app sees it. [title] and [body] hold names and amounts, so
/// they are shown but never logged.
class PushMessage {
  const PushMessage({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;
  final Map<String, String> data;

  PushPayload get payload => PushPayload.fromData(data);
}

abstract interface class PushMessaging {
  /// Null when push is unavailable on this phone (no Google Play services).
  Future<String?> token();

  Stream<String> get onTokenRefresh;

  /// Kills the current token so pushes sent to it can no longer arrive.
  Future<void> deleteToken();

  Future<PushPermission> permissionStatus();

  /// Shows the system dialog (Android 13+). Returns the resulting status.
  Future<PushPermission> requestPermission();

  /// Pushes that arrive while the app is open (Android shows none itself).
  Stream<PushMessage> get onForegroundMessage;

  /// The user tapped a notification while the app was in the background.
  Stream<PushMessage> get onOpenedMessage;

  /// The notification that started the app from a closed state, if any.
  Future<PushMessage?> initialMessage();
}
