import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tiyn_app/app/config.dart';
import 'package:tiyn_app/app/providers.dart';
import 'package:tiyn_app/core/network/api_client.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/core/session/session_events.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/application/sign_in_controller.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/fakes.dart';

const _userJson = {'id': 'u1', 'role': 'TEEN', 'displayName': 'Dana'};

class _Harness {
  _Harness({required this.handler, FakeGoogleIdentity? google})
    : google = google ?? FakeGoogleIdentity(),
      tokens = FakeTokenStorage() {
    container = ProviderContainer(
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
        googleIdentityProvider.overrideWithValue(this.google),
        apiClientProvider.overrideWith(
          (ref) => ApiClient(
            baseUrl: Uri.parse('https://api.test'),
            tokens: tokens,
            onUnauthorized: () =>
                ref.read(sessionExpiredProvider.notifier).expired(),
            dio: Dio()
              ..httpClientAdapter = FakeAdapter((options, body) {
                bodies.add(
                  body.isEmpty
                      ? <String, Object?>{}
                      : jsonDecode(body) as Map<String, Object?>,
                );
                return handler(options, bodies.length);
              }),
          ),
        ),
      ],
    );
    container.listen(signInControllerProvider, (_, _) {});
  }

  final Future<ResponseBody> Function(RequestOptions, int call) handler;
  final FakeGoogleIdentity google;
  final FakeTokenStorage tokens;
  final bodies = <Map<String, Object?>>[];
  late final ProviderContainer container;

  SignInController get controller =>
      container.read(signInControllerProvider.notifier);
  SignInState get state => container.read(signInControllerProvider);
  Object? get signedInUser => container.read(authControllerProvider).value;

  Future<void> ready() => container.read(authControllerProvider.future);
}

Future<ResponseBody> _session() async =>
    jsonBody({'token': 'jwt', 'user': _userJson});

Future<ResponseBody> _roleRequired() async =>
    jsonBody({'error': 'role_required'}, status: 422);

void main() {
  late _Harness h;
  tearDown(() => h.container.dispose());

  test('an existing account signs in without a role step', () async {
    h = _Harness(handler: (_, _) => _session());
    await h.ready();

    await h.controller.continueWithGoogle();

    expect(h.signedInUser, isNotNull);
    expect(h.state, isNot(isA<ChoosingRole>()));
    expect(h.bodies.single.containsKey('role'), isFalse);
    expect(h.tokens.token, 'jwt');
  });

  test('a new account asks for a role, then resends the same token', () async {
    h = _Harness(
      handler: (_, call) => call == 1 ? _roleRequired() : _session(),
    );
    await h.ready();

    await h.controller.continueWithGoogle();
    final choosing = h.state as ChoosingRole;
    expect(choosing.credential.email, 'user@example.com');
    expect(choosing.selected, isNull);
    expect(h.signedInUser, isNull);
    expect(h.bodies.first.containsKey('role'), isFalse);

    h.controller.selectRole(Role.teen);
    await h.controller.confirmRole();

    expect(h.bodies, hasLength(2));
    expect(h.bodies[1]['role'], 'TEEN');
    expect(h.bodies[1]['idToken'], h.bodies[0]['idToken']);
    expect(h.signedInUser, isNotNull);
  });

  test('confirm does nothing until a role is selected', () async {
    h = _Harness(handler: (_, _) => _roleRequired());
    await h.ready();
    await h.controller.continueWithGoogle();

    await h.controller.confirmRole();

    expect(h.bodies, hasLength(1));
    expect(h.state, isA<ChoosingRole>());
  });

  test('cancelling Google returns to Welcome without an error', () async {
    h = _Harness(
      handler: (_, _) => _session(),
      google: FakeGoogleIdentity(
        signInError: const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
        ),
      ),
    );
    await h.ready();

    await h.controller.continueWithGoogle();

    expect((h.state as Welcome).error, isNull);
    expect(h.bodies, isEmpty);
  });

  test('another Google failure returns to Welcome with the error', () async {
    h = _Harness(
      handler: (_, _) => _session(),
      google: FakeGoogleIdentity(
        signInError: const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
        ),
      ),
    );
    await h.ready();

    await h.controller.continueWithGoogle();

    expect((h.state as Welcome).error, isA<GoogleSignInException>());
  });

  test('invalid_identity on confirm signs out of Google and expires', () async {
    h = _Harness(
      handler: (_, call) => call == 1
          ? _roleRequired()
          : Future.value(jsonBody({'error': 'invalid_identity'}, status: 401)),
    );
    await h.ready();
    await h.controller.continueWithGoogle();
    h.controller.selectRole(Role.parent);

    await h.controller.confirmRole();

    expect((h.state as Welcome).error, isA<SignInExpired>());
    expect(h.google.signOutCalls, 1);
    expect(h.signedInUser, isNull);
  });

  test('a network error on confirm keeps the selection', () async {
    h = _Harness(
      handler: (options, call) async {
        if (call == 1) return _roleRequired();
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        );
      },
    );
    await h.ready();
    await h.controller.continueWithGoogle();
    h.controller.selectRole(Role.parent);

    await h.controller.confirmRole();

    final choosing = h.state as ChoosingRole;
    expect(choosing.selected, Role.parent);
    expect(choosing.sending, isFalse);
    expect(choosing.error, isA<ApiException>());
  });

  test(
    'useAnotherAccount signs out of Google and returns to Welcome',
    () async {
      h = _Harness(handler: (_, _) => _roleRequired());
      await h.ready();
      await h.controller.continueWithGoogle();

      await h.controller.useAnotherAccount();

      expect(h.state, isA<Welcome>());
      expect(h.google.signOutCalls, 1);
    },
  );
}
