import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/design/theme.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/application/sign_in_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/auth/presentation/splash_screen.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';
import 'package:tiyn_app/features/family/presentation/parent_code_screen.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

import '../helpers/pump_app.dart';

// Worst realistic case: a small phone, large system text, the two languages
// with the longest strings. Layout is fixed by wrapping or scrolling, never by
// shrinking fonts.

const _teenUser = User(
  id: '2',
  role: Role.teen,
  displayName: 'Айгерім Нұрланқызы',
);
const _parentUser = User(
  id: '1',
  role: Role.parent,
  displayName: 'Айгерім',
  joinCode: 'SXVPUR',
);
const _teens = [
  FamilyMember(id: '2', role: Role.teen, displayName: 'Данияр Серікұлы'),
  FamilyMember(id: '3', role: Role.teen, displayName: 'Айшолпан Нұрланқызы'),
  FamilyMember(id: '4', role: Role.teen, displayName: 'Ярослав Константинович'),
];
const _parents = [
  FamilyMember(id: '1', role: Role.parent, displayName: 'Айгерім Нұрланқызы'),
  FamilyMember(id: '5', role: Role.parent, displayName: 'Константин Петрович'),
];

class _Auth extends AuthController {
  _Auth(this._user);

  final User? _user;

  @override
  Future<User?> build() async => _user;
}

class _Family extends FamilyController {
  _Family(this._load);

  final Future<List<FamilyMember>> Function() _load;
  Object? joinError;

  @override
  Future<List<FamilyMember>> build() => _load();

  @override
  Future<void> join(String code) async {
    final error = joinError;
    if (error != null) throw error;
  }
}

class _Seeded extends SignInController {
  _Seeded(this._seed);

  final SignInState _seed;

  @override
  SignInState build() => _seed;
}

void _smallPhone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(360, 640)
    ..devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearAllTestValues();
  });
}

/// Pumps one screen on its own (no router) with the real theme and l10n.
Future<void> _pumpScreen(
  WidgetTester tester,
  String locale,
  Widget screen, {
  List<Override> overrides = const [],
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: overrides,
      child: MaterialApp(
        theme: buildTheme(),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in const ['ru', 'kk']) {
    group('no overflow in $locale at 360x640, 1.3x text:', () {
      testWidgets('sign-in welcome', (tester) async {
        _smallPhone(tester);
        await pumpApp(
          tester,
          overrides: [authControllerProvider.overrideWith(() => _Auth(null))],
          locale: Locale(locale),
        );
        expect(find.byType(FilledButton), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('sign-in role step with a long email', (tester) async {
        _smallPhone(tester);
        await pumpApp(
          tester,
          overrides: [
            authControllerProvider.overrideWith(() => _Auth(null)),
            signInControllerProvider.overrideWith(
              () => _Seeded(
                ChoosingRole(
                  credential: (
                    idToken: 't',
                    email: 'aigerim.nurlanovna.example@gmail.com',
                  ),
                  selected: Role.teen,
                  error: const ApiException(code: 'network_error'),
                ),
              ),
            ),
          ],
          locale: Locale(locale),
        );
        expect(find.byType(FilledButton), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('join screen with an error shown', (tester) async {
        _smallPhone(tester);
        final family = _Family(() async => const []);
        family.joinError = const ApiException(code: 'invalid_join_code');
        await pumpApp(
          tester,
          overrides: [
            authControllerProvider.overrideWith(() => _Auth(_teenUser)),
            familyControllerProvider.overrideWith(() => family),
          ],
          locale: Locale(locale),
        );
        await tester.enterText(find.byType(TextField), 'SXVPUR');
        await tester.pumpAndSettle();
        expect(
          find.text(
            AppLocalizations.of(tester.element(find.byType(TextField)))
                .errorInvalidJoinCode,
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('parent home with 3 teens', (tester) async {
        _smallPhone(tester);
        await pumpApp(
          tester,
          overrides: [
            authControllerProvider.overrideWith(() => _Auth(_parentUser)),
            familyControllerProvider.overrideWith(
              () => _Family(() async => _teens),
            ),
          ],
          locale: Locale(locale),
        );
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('parent home error card', (tester) async {
        _smallPhone(tester);
        await _pumpScreen(
          tester,
          locale,
          ParentCodeScreen(joinCode: 'SXVPUR', onSignOut: () {}),
          overrides: [
            authControllerProvider.overrideWith(() => _Auth(_parentUser)),
            familyControllerProvider.overrideWith(
              () => _Family(
                () async => throw const ApiException(code: 'network_error'),
              ),
            ),
          ],
        );
        expect(find.byType(ParentCodeScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('teen home inside its shell', (tester) async {
        _smallPhone(tester);
        await pumpApp(
          tester,
          overrides: [
            authControllerProvider.overrideWith(() => _Auth(_teenUser)),
            familyControllerProvider.overrideWith(
              () => _Family(() async => _parents),
            ),
          ],
          locale: Locale(locale),
        );
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('splash error with sign-out', (tester) async {
        _smallPhone(tester);
        await _pumpScreen(
          tester,
          locale,
          SplashScreen(hasError: true, onRetry: () {}, onSignOut: () {}),
        );
        expect(find.byType(TextButton), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
