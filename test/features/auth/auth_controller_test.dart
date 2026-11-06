import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/app/config.dart';
import 'package:tiyn_app/app/providers.dart';
import 'package:tiyn_app/core/network/api_client.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/core/session/session_events.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/fakes.dart';

const _userJson = {
  'id': 'u1',
  'role': 'PARENT',
  'displayName': 'Aigerim',
  'joinCode': 'SXVPUR',
};

ProviderContainer _container({
  required FakeTokenStorage tokens,
  required FakeHandler handler,
  FakeGoogleIdentity? google,
}) {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      appConfigProvider.overrideWithValue(
        AppConfig(
          flavor: Flavor.dev,
          apiBaseUrl: Uri.parse('https://api.test'),
          googleServerClientId: null,
        ),
      ),
      tokenStorageProvider.overrideWithValue(tokens),
      googleIdentityProvider.overrideWithValue(google ?? FakeGoogleIdentity()),
      apiClientProvider.overrideWith(
        (ref) => ApiClient(
          baseUrl: Uri.parse('https://api.test'),
          tokens: tokens,
          onUnauthorized: () =>
              ref.read(sessionExpiredProvider.notifier).expired(),
          dio: Dio()..httpClientAdapter = FakeAdapter(handler),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('no token gives a signed-out state', () async {
    final container = _container(
      tokens: FakeTokenStorage(),
      handler: (_, _) async => throw StateError('no request expected'),
    );
    expect(await container.read(authControllerProvider.future), isNull);
  });

  test('a token and /me OK gives the user', () async {
    final container = _container(
      tokens: FakeTokenStorage('jwt'),
      handler: (_, _) async => jsonBody(_userJson),
    );
    final user = await container.read(authControllerProvider.future);
    expect(user?.id, 'u1');
    expect(user?.role, Role.parent);
  });

  test(
    'a token and /me 401 gives null, clears the token, changes state once',
    () async {
      final tokens = FakeTokenStorage('jwt');
      final container = _container(
        tokens: tokens,
        handler: (_, _) async =>
            jsonBody({'error': 'unauthenticated'}, status: 401),
      );
      final states = <AsyncValue<User?>>[];
      container.listen(authControllerProvider, (_, next) => states.add(next));

      expect(await container.read(authControllerProvider.future), isNull);
      await Future<void>.delayed(Duration.zero);

      expect(tokens.token, isNull);
      expect(states.where((s) => s.hasValue).length, 1);
      expect(states.any((s) => s.hasError), isFalse);
    },
  );

  test('a session-expired event after sign-in signs the user out', () async {
    final tokens = FakeTokenStorage('jwt');
    final container = _container(
      tokens: tokens,
      handler: (_, _) async => jsonBody(_userJson),
    );
    container.listen(authControllerProvider, (_, _) {});
    expect(await container.read(authControllerProvider.future), isNotNull);

    container.read(sessionExpiredProvider.notifier).expired();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(authControllerProvider).value, isNull);
    expect(tokens.token, isNull);
  });

  group('signOut', () {
    FakeHandler meHandler() =>
        (_, _) async => jsonBody(_userJson);

    test('does not wait for Google to finish signing out', () async {
      final tokens = FakeTokenStorage('t');
      final google = FakeGoogleIdentity()
        ..signOutBlocker = Completer<void>().future; // never completes
      final container = _container(
        tokens: tokens,
        handler: meHandler(),
        google: google,
      );
      expect(await container.read(authControllerProvider.future), isNotNull);

      await container
          .read(authControllerProvider.notifier)
          .signOut()
          .timeout(const Duration(seconds: 1));

      expect(container.read(authControllerProvider).value, isNull);
      expect(tokens.token, isNull);
      expect(google.signOutCalls, 1);
    });

    test('a failing Google sign-out does not surface or crash', () async {
      final tokens = FakeTokenStorage('t');
      final google = FakeGoogleIdentity()..signOutError = StateError('gms');
      final container = _container(
        tokens: tokens,
        handler: meHandler(),
        google: google,
      );
      await container.read(authControllerProvider.future);

      await container.read(authControllerProvider.notifier).signOut();
      await Future<void>.delayed(Duration.zero);

      expect(container.read(authControllerProvider).value, isNull);
      expect(tokens.token, isNull);
    });
  });
}
