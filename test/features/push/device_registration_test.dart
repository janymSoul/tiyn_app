import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/app/config.dart';
import 'package:tiyn_app/app/providers.dart';
import 'package:tiyn_app/core/network/api_client.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/push/push_messaging.dart';
import 'package:tiyn_app/core/push/push_providers.dart';
import 'package:tiyn_app/core/session/session_events.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/push/application/device_registration.dart';
import 'package:tiyn_app/features/push/data/push_store.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/fake_push_backend.dart';
import '../../helpers/fake_push_messaging.dart';
import '../../helpers/fakes.dart';

const _userJson = {'id': 'u1', 'role': 'PARENT', 'displayName': 'Aigerim'};

class _Setup {
  _Setup({Flavor flavor = Flavor.staging, bool signedIn = true})
    : tokens = FakeTokenStorage(signedIn ? 'jwt-1' : null) {
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig(
            flavor: flavor,
            apiBaseUrl: Uri.parse('https://api.test'),
            googleServerClientId: null,
          ),
        ),
        tokenStorageProvider.overrideWithValue(tokens),
        googleIdentityProvider.overrideWithValue(FakeGoogleIdentity()),
        apiClientProvider.overrideWith(
          (ref) => ApiClient(
            baseUrl: Uri.parse('https://api.test'),
            tokens: tokens,
            onUnauthorized: () =>
                ref.read(sessionExpiredProvider.notifier).expired(),
            dio: Dio()
              ..httpClientAdapter = FakeAdapter(
                (_, _) async => jsonBody(_userJson),
              ),
          ),
        ),
        pushMessagingProvider.overrideWithValue(push),
        pushStoreProvider.overrideWithValue(store),
        deviceRepositoryProvider.overrideWithValue(repo),
        deviceLocaleProvider.overrideWithValue(() => locale),
        devLogProvider.overrideWithValue(logged.add),
      ],
    );
    addTearDown(container.dispose);
  }

  final FakeTokenStorage tokens;
  final push = FakePushMessaging();
  final store = FakePushStore();
  final repo = FakeDeviceRepository();
  final logged = <String>[];
  Locale locale = const Locale('en');
  late final ProviderContainer container;

  /// Starts the app-level objects the way TiynApp does.
  Future<void> start() async {
    container.listen(authControllerProvider, (_, _) {});
    await container.read(authControllerProvider.future);
    // TiynApp watches it; a provider nobody listens to has its listeners paused.
    container.listen(deviceRegistrationProvider, (_, _) {});
    await settle();
  }

  DeviceRegistration get registration =>
      container.read(deviceRegistrationProvider);

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 10));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('registration', () {
    test('PUT after sign-in with the token and the app locale', () async {
      final s = _Setup()..locale = const Locale('kk');
      await s.start();
      expect(s.repo.registered, [(token: 'fcm-token-1', locale: 'kk')]);
      expect(s.store.registration?.userId, 'u1');
    });

    test('any locale except Kazakh is sent as ru', () async {
      final s = _Setup()..locale = const Locale('en');
      await s.start();
      expect(s.repo.registered.single.locale, 'ru');
    });

    test('PUT again when the token refreshes', () async {
      final s = _Setup();
      await s.start();
      s.push.emitTokenRefresh('fcm-token-2');
      await s.settle();
      expect(s.repo.registered.map((r) => r.token), [
        'fcm-token-1',
        'fcm-token-2',
      ]);
    });

    test('no PUT when nothing changed, on resume or refresh', () async {
      final s = _Setup();
      await s.start();
      await s.registration.sync();
      s.push.emitTokenRefresh('fcm-token-1');
      await s.settle();
      expect(s.repo.registered, hasLength(1));
    });

    test('PUT when the locale changes', () async {
      final s = _Setup()..locale = const Locale('ru');
      await s.start();
      s.locale = const Locale('kk');
      await s.registration.sync();
      expect(s.repo.registered.map((r) => r.locale), ['ru', 'kk']);
    });

    test('PUT when only the user changed (same token)', () async {
      final s = _Setup();
      await s.start();
      s.store.registration = const DeviceRecord(
        userId: 'someone-else',
        token: 'fcm-token-1',
        locale: 'ru',
      );
      await s.registration.sync();
      expect(s.repo.registered, hasLength(2));
    });

    test(
      'a failed PUT is retried on the next resume and never throws',
      () async {
        final s = _Setup();
        s.repo.registerError = const ApiException(code: 'network_error');
        await s.start();
        expect(s.repo.registered, isEmpty);
        expect(s.store.registration, isNull);

        s.repo.registerError = null;
        await s.registration.sync();
        expect(s.repo.registered, hasLength(1));
      },
    );

    test('registers even when notifications are denied', () async {
      final s = _Setup();
      s.push.permission = PushPermission.denied;
      await s.start();
      expect(s.repo.registered, hasLength(1));
    });

    test(
      'nothing is sent while signed out or when there is no token',
      () async {
        final out = _Setup(signedIn: false);
        await out.start();
        expect(out.repo.registered, isEmpty);

        final noToken = _Setup();
        noToken.push.tokenValue = null;
        await noToken.start();
        expect(noToken.repo.registered, isEmpty);
      },
    );

    test('a PUT that finishes after sign-out is not stored', () async {
      final s = _Setup(signedIn: false);
      await s.start();
      s.tokens.token = 'jwt-1';
      s.container.invalidate(authControllerProvider);
      await s.container.read(authControllerProvider.future);
      await s.container.read(authControllerProvider.notifier).signOut();
      await s.settle();
      expect(s.store.registration, isNull);
    });

    test('the token is logged in the dev flavor only', () async {
      final dev = _Setup(flavor: Flavor.dev);
      await dev.start();
      expect(dev.logged, ['FCM token: fcm-token-1']);

      for (final flavor in [Flavor.staging, Flavor.prod]) {
        final other = _Setup(flavor: flavor);
        await other.start();
        expect(other.logged, isEmpty, reason: flavor.name);
      }
    });
  });

  group('sign-out', () {
    test(
      'returns at once even when DELETE hangs, and still kills the token',
      () async {
        final s = _Setup();
        await s.start();
        s.repo.unregisterBlocker = Completer<void>();

        await s.container
            .read(authControllerProvider.notifier)
            .signOut()
            .timeout(const Duration(milliseconds: 500));

        expect(s.container.read(authControllerProvider).value, isNull);
        expect(s.tokens.token, isNull);
        expect(s.repo.unregistered.single, (
          token: 'fcm-token-1',
          authToken: 'jwt-1',
        ));
      },
    );

    test('deleteToken is called when DELETE fails', () async {
      final s = _Setup();
      await s.start();
      s.repo.unregisterError = const ApiException(code: 'network_error');
      await s.container.read(authControllerProvider.notifier).signOut();
      await s.settle();
      expect(s.push.deleteTokenCalls, 1);
      expect(s.store.registration, isNull);
      expect(s.store.pendingDelete, isFalse);
    });

    test('deleteToken is called after the DELETE times out', () async {
      final s = _Setup();
      await s.start();
      s.repo.unregisterBlocker = Completer<void>();
      await s.container.read(authControllerProvider.notifier).signOut();
      await Future<void>.delayed(const Duration(milliseconds: 3200));
      expect(s.push.deleteTokenCalls, 1);
    });

    test(
      'an expired session still kills the token, without a DELETE',
      () async {
        final s = _Setup();
        await s.start();
        s.container.read(sessionExpiredProvider.notifier).expired();
        await s.settle();
        expect(s.repo.unregistered, isEmpty);
        expect(s.push.deleteTokenCalls, 1);
        expect(s.store.registration, isNull);
      },
    );

    test(
      'a failed deleteToken leaves a marker that is retried later',
      () async {
        final s = _Setup();
        await s.start();
        s.push.deleteTokenError = StateError('offline');
        await s.container.read(authControllerProvider.notifier).signOut();
        await s.settle();
        expect(s.store.pendingDelete, isTrue);

        s.push.deleteTokenError = null;
        await s.registration.sync();
        expect(s.push.deleteTokenCalls, 2);
        expect(s.store.pendingDelete, isFalse);
      },
    );

    test(
      'a pending delete is finished before the next user registers',
      () async {
        final s = _Setup();
        s.store.pendingDelete = true;
        await s.start();
        expect(s.push.deleteTokenCalls, 1);
        expect(s.repo.registered, hasLength(1));
      },
    );
  });

  group('ApiClient delete with an explicit token', () {
    ApiClient client(
      FakeAdapter adapter,
      FakeTokenStorage tokens,
      void Function() onUnauthorized,
    ) => ApiClient(
      baseUrl: Uri.parse('https://api.test'),
      tokens: tokens,
      onUnauthorized: onUnauthorized,
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
    );

    test('sends the given bearer even when storage is already empty', () async {
      final adapter = FakeAdapter((_, _) async => emptyBody(204));
      await client(
        adapter,
        FakeTokenStorage(),
        () {},
      ).delete('/devices', body: {'token': 't'}, authToken: 'old-jwt');
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer old-jwt',
      );
    });

    test(
      'a 401 on it does not count as the current session expiring',
      () async {
        var expired = 0;
        final adapter = FakeAdapter(
          (_, _) async => jsonBody({'error': 'x'}, status: 401),
        );
        await expectLater(
          client(
            adapter,
            FakeTokenStorage('new-jwt'),
            () => expired++,
          ).delete('/devices', authToken: 'old-jwt'),
          throwsA(isA<ApiException>()),
        );
        expect(expired, 0);
      },
    );

    test('a normal request still reports a 401', () async {
      var expired = 0;
      final adapter = FakeAdapter(
        (_, _) async => jsonBody({'error': 'x'}, status: 401),
      );
      await expectLater(
        client(
          adapter,
          FakeTokenStorage('jwt'),
          () => expired++,
        ).delete('/devices'),
        throwsA(isA<ApiException>()),
      );
      expect(expired, 1);
    });
  });
}
