import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/app/config.dart';
import 'package:tiyn_app/app/providers.dart';
import 'package:tiyn_app/core/l10n/app_locale.dart';
import 'package:tiyn_app/core/push/push_messaging.dart';
import 'package:tiyn_app/core/push/push_providers.dart';
import 'package:tiyn_app/core/session/session_end.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/push/data/device_repository.dart';
import 'package:tiyn_app/features/push/data/push_store.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => DeviceRepository(ref.watch(apiClientProvider)),
);

final pushStoreProvider = Provider<PushStore>((_) => PushStore());

/// The device's locale, read at call time so a language change is noticed.
final deviceLocaleProvider = Provider<Locale Function()>(
  (_) =>
      () => PlatformDispatcher.instance.locale,
);

/// Where the dev-only token line goes. Replaced in tests.
final devLogProvider = Provider<void Function(String)>(
  (_) =>
      (line) => debugPrint(line),
);

/// Keeps this phone's FCM token registered for the signed-in user and
/// unregistered when they leave.
///
/// Registration is independent of the notification permission, never shows an
/// error to the user, and is retried on the next resume after a failure.
class DeviceRegistration implements SessionEndHandler {
  DeviceRegistration(this._ref) {
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(sync()));
    _refreshSub = _ref
        .read(pushMessagingProvider)
        .onTokenRefresh
        .listen((_) => unawaited(sync()), onError: (Object _) {});
    _ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (next != null) {
        _signingOut = false;
        unawaited(sync());
      } else if (previous != null) {
        unawaited(_sessionEnded());
      }
    }, fireImmediately: true);
    unawaited(sync());
    final hooks = _ref.read(sessionEndHooksProvider)..handler = this;
    _ref.onDispose(() {
      if (identical(hooks.handler, this)) {
        hooks.handler = const NoSessionEndHandler();
      }
      _lifecycle.dispose();
      unawaited(_refreshSub.cancel());
    });
  }

  static const _deleteTimeout = Duration(seconds: 3);
  static const _tokenTimeout = Duration(seconds: 10);

  final Ref _ref;
  late final AppLifecycleListener _lifecycle;
  late final StreamSubscription<String> _refreshSub;
  bool _syncing = false;
  bool _again = false;
  bool _signingOut = false;
  bool _cleanupHandled = false;
  String? _loggedToken;

  PushMessaging get _push => _ref.read(pushMessagingProvider);
  PushStore get _store => _ref.read(pushStoreProvider);

  /// Single-flight: a call during a run schedules one more pass.
  Future<void> sync() async {
    if (_syncing) {
      _again = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _again = false;
        try {
          await _syncOnce();
        } on Object catch (e) {
          // Retried on the next resume; the user never sees this.
          debugPrint('Device registration failed: ${e.runtimeType}');
        }
      } while (_again);
    } finally {
      _syncing = false;
    }
  }

  Future<void> _syncOnce() async {
    final userId = _ref.read(currentUserIdProvider);
    // Signed out: the only job is to finish killing an old token whose
    // deletion failed (for example the sign-out happened offline).
    if (userId == null) return _retryPendingTokenDelete();
    if (_signingOut) return;

    await _retryPendingTokenDelete();

    final token = await _push.token();
    if (token == null) return;
    if (_ref.read(currentUserIdProvider) != userId || _signingOut) return;

    _logTokenInDev(token);

    final record = DeviceRecord(
      userId: userId,
      token: token,
      locale: pushLocale(_ref.read(deviceLocaleProvider)()),
    );
    if (await _store.readRegistration() == record) return;

    await _ref
        .read(deviceRepositoryProvider)
        .register(token: record.token, locale: record.locale);
    if (_ref.read(currentUserIdProvider) != userId || _signingOut) return;
    await _store.writeRegistration(record);
  }

  void _logTokenInDev(String token) {
    // The one deliberate exception to "never log tokens": dev builds only, so
    // a test push can be sent from the Firebase console.
    final flavor = _ref.read(appConfigProvider).flavor;
    if (flavor == Flavor.dev && kDebugMode && token != _loggedToken) {
      _loggedToken = token;
      _ref.read(devLogProvider)('FCM token: $token');
    }
  }

  /// Sign-out started: kill the old token in the background and return.
  @override
  Future<void> beginSignOut() async {
    _signingOut = true;
    _cleanupHandled = true;
    final jwt = await _ref.read(tokenStorageProvider).read();
    final registered = await _store.readRegistration();
    await _store.markPendingTokenDelete();
    unawaited(_cleanup(jwt: jwt, registeredToken: registered?.token));
  }

  /// The session ended some other way (expired, `/me` said 401): there is no
  /// JWT left, so only the local token can be killed.
  Future<void> _sessionEnded() async {
    if (_cleanupHandled) {
      _cleanupHandled = false;
      return;
    }
    _signingOut = true;
    await _store.markPendingTokenDelete();
    await _cleanup(jwt: null, registeredToken: null);
  }

  Future<void> _cleanup({
    required String? jwt,
    required String? registeredToken,
  }) async {
    if (jwt != null && registeredToken != null) {
      try {
        await _ref
            .read(deviceRepositoryProvider)
            .unregister(token: registeredToken, authToken: jwt)
            .timeout(_deleteTimeout);
      } on Object catch (e) {
        debugPrint('Device unregister failed: ${e.runtimeType}');
      }
    }
    await _killLocalToken();
    try {
      await _store.clearRegistration();
    } on Object catch (e) {
      debugPrint('Clearing registration failed: ${e.runtimeType}');
    }
  }

  Future<void> _killLocalToken() async {
    try {
      await _push.deleteToken().timeout(_tokenTimeout);
      await _store.clearPendingTokenDelete();
    } on Object catch (e) {
      // The marker stays, so the next start or resume tries again.
      debugPrint('Deleting the push token failed: ${e.runtimeType}');
    }
  }

  Future<void> _retryPendingTokenDelete() async {
    if (await _store.hasPendingTokenDelete()) await _killLocalToken();
  }
}

final deviceRegistrationProvider = Provider<DeviceRegistration>(
  DeviceRegistration.new,
);
