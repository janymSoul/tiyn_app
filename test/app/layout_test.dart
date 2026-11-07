import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiyn_app/app/router/routes.dart';
import 'package:tiyn_app/core/bank/bank_launcher.dart';
import 'package:tiyn_app/core/bank/bank_providers.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/design/theme.dart';
import 'package:tiyn_app/design/widgets/busy_button.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/application/sign_in_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/auth/presentation/splash_screen.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';
import 'package:tiyn_app/features/parent/presentation/parent_home_screen.dart';
import 'package:tiyn_app/features/payouts/application/payout_providers.dart';
import 'package:tiyn_app/features/payouts/data/cancel_reason.dart';
import 'package:tiyn_app/features/payouts/data/payout.dart';
import 'package:tiyn_app/features/payouts/data/payout_state.dart';
import 'package:tiyn_app/features/tasks/application/task_providers.dart';
import 'package:tiyn_app/features/tasks/data/proof.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';
import 'package:tiyn_app/features/teen/application/dashboard_controller.dart';
import 'package:tiyn_app/features/teen/data/dashboard.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

import '../helpers/fake_bank_launcher.dart';
import '../helpers/fake_dashboard.dart';
import '../helpers/fake_payouts.dart';
import '../helpers/fake_tasks.dart';
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
            payoutRepositoryProvider.overrideWithValue(FakePayoutRepository()),
            taskRepositoryProvider.overrideWithValue(
              FakeTaskRepository([
                fakeTask(id: 's', teenId: '4', state: TaskState.submitted),
                fakeTask(id: 'a', teenId: '2'),
              ]),
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
          const ParentHomeScreen(),
          overrides: [
            payoutRepositoryProvider.overrideWithValue(FakePayoutRepository()),
            taskRepositoryProvider.overrideWithValue(FakeTaskRepository()),
            authControllerProvider.overrideWith(() => _Auth(_parentUser)),
            familyControllerProvider.overrideWith(
              () => _Family(
                () async => throw const ApiException(code: 'network_error'),
              ),
            ),
          ],
        );
        expect(find.byType(ParentHomeScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('create form: errors, penalty and the locked retry state', (
        tester,
      ) async {
        _smallPhone(tester);
        final tasks = FakeTaskRepository()
          ..onCreate = (_, _) async =>
              throw const ApiException(code: 'timeout');
        await pumpApp(
          tester,
          overrides: [
            authControllerProvider.overrideWith(() => _Auth(_parentUser)),
            familyControllerProvider.overrideWith(
              () => _Family(() async => _teens),
            ),
            payoutRepositoryProvider.overrideWithValue(FakePayoutRepository()),
            taskRepositoryProvider.overrideWithValue(tasks),
          ],
          locale: Locale(locale),
        );
        unawaited(routerOf(tester).push(Routes.parentNewFor('2')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Submit empty: every inline error at once.
        final submit = find.byType(FilledButton);
        await tester.ensureVisible(submit);
        await tester.pumpAndSettle();
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Open the penalty row, fill in long text, then fail with a timeout.
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();
        final fields = find.byType(TextField);
        await tester.enterText(
          fields.at(0),
          'Вымыть всю посуду после большого семейного ужина и протереть',
        );
        await tester.enterText(fields.at(1), '1500');
        await tester.pump();
        await tester.ensureVisible(submit);
        await tester.pumpAndSettle();
        await tester.tap(submit);
        await tester.pumpAndSettle();
        // "Edit details" sits under the button, below the fold.
        await tester.scrollUntilVisible(
          find.byType(TextButton),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('review: list, long proof and the reject sheet', (
        tester,
      ) async {
        _smallPhone(tester);
        final tasks =
            FakeTaskRepository([
                fakeTask(
                  id: 'r',
                  teenId: '4',
                  state: TaskState.submitted,
                  title: 'Вымыть всю посуду после большого семейного ужина',
                  reward: const Money.kzt(1250000050),
                  submittedAt: DateTime.utc(2026, 11, 7, 8),
                ),
              ])
              ..proofsById['r'] = [
                Proof(
                  attemptNo: 2,
                  text: 'Всё готово, ' * 40,
                  createdAt: DateTime.utc(2026, 11, 7, 9),
                ),
              ];
        await pumpApp(
          tester,
          overrides: [
            authControllerProvider.overrideWith(() => _Auth(_parentUser)),
            familyControllerProvider.overrideWith(
              () => _Family(() async => _teens),
            ),
            payoutRepositoryProvider.overrideWithValue(FakePayoutRepository()),
            taskRepositoryProvider.overrideWithValue(tasks),
          ],
          locale: Locale(locale),
        );
        await tester.tap(find.byIcon(Icons.task_alt));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.textContaining('Вымыть'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final reject = find.text(
          AppLocalizations.of(tester.element(find.byType(Scaffold).last))
              .reviewReject,
        );
        await tester.scrollUntilVisible(
          reject,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(reject);
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('teen detail: tasks, finished group and milestones', (
        tester,
      ) async {
        _smallPhone(tester);
        final tasks = FakeTaskRepository([
          fakeTask(
            id: 'a',
            teenId: '2',
            title: 'Вымыть всю посуду после большого семейного ужина',
          ),
          fakeTask(
            id: 'b',
            teenId: '2',
            state: TaskState.submitted,
            title: 'Үйдегі барлық бөлмелерді жинап, шаңын сүрту',
            reward: const Money.kzt(1250000050),
          ),
          fakeTask(
            id: 'c',
            teenId: '2',
            state: TaskState.approved,
            title: 'Готово',
          ),
          fakeTask(
            id: 'm',
            teenId: '2',
            kind: TaskKind.milestone,
            title: 'Подготовка к школьному учебному году целиком',
          ),
          fakeTask(
            id: 'm1',
            teenId: '2',
            milestoneId: 'm',
            state: TaskState.approved,
          ),
          fakeTask(id: 'm2', teenId: '2', milestoneId: 'm'),
        ]);
        await pumpApp(
          tester,
          overrides: [
            authControllerProvider.overrideWith(() => _Auth(_parentUser)),
            familyControllerProvider.overrideWith(
              () => _Family(() async => _teens),
            ),
            payoutRepositoryProvider.overrideWithValue(FakePayoutRepository()),
            taskRepositoryProvider.overrideWithValue(tasks),
          ],
          locale: Locale(locale),
        );
        await tester.tap(find.textContaining('Данияр'));
        await tester.pumpAndSettle();
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);

        await tester.scrollUntilVisible(
          find.byType(ExpansionTile),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.byType(ExpansionTile));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Second segment: two open tasks, one open milestone.
        await tester.tap(
          find.descendant(
            of: find.byWidgetPredicate((w) => w is SegmentedButton),
            matching: find.textContaining('(1)'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('teen home with a milestone, pending chip and long text', (
        tester,
      ) async {
        _smallPhone(tester);
        await pumpApp(
          tester,
          overrides: [
            authControllerProvider.overrideWith(() => _Auth(_teenUser)),
            familyControllerProvider.overrideWith(
              () => _Family(() async => _parents),
            ),
            dashboardRepositoryProvider.overrideWithValue(
              FakeDashboardRepository(
                fakeDashboard(
                  balance: const Money.kzt(123456789000),
                  available: const Money.kzt(123456789000),
                  pending: const Money.kzt(1250000050),
                  chores: [
                    fakeChore(
                      id: 'a',
                      title: 'Вымыть всю посуду после большого ужина',
                    ),
                    fakeChore(
                      id: 'b',
                      title: 'Үйдегі барлық бөлмелерді жинап, шаңын сүрту',
                      state: TaskState.submitted,
                      reward: const Money.kzt(1250000050),
                    ),
                    fakeChore(
                      id: 'c',
                      title: 'Первый шаг большого этапа',
                      milestoneId: 'm',
                    ),
                  ],
                  milestones: [
                    fakeMilestone(
                      id: 'm',
                      title: 'Подготовка к школьному учебному году целиком',
                      approvedTasks: 1,
                      totalTasks: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
          locale: Locale(locale),
        );
        expect(find.byType(NavigationBar), findsNothing);
        expect(tester.takeException(), isNull);

        // The milestone is below the fold: scroll to it, overflow-checking
        // every card on the way.
        await tester.scrollUntilVisible(
          find.byType(LinearProgressIndicator),
          200,
        );
        await tester.drag(find.byType(ListView), const Offset(0, -2000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('teen home error card', (tester) async {
        _smallPhone(tester);
        await pumpApp(
          tester,
          overrides: [
            authControllerProvider.overrideWith(() => _Auth(_teenUser)),
            familyControllerProvider.overrideWith(
              () => _Family(() async => _parents),
            ),
            dashboardRepositoryProvider.overrideWithValue(
              FakeDashboardRepository()
                ..error = const ApiException(code: 'network_error'),
            ),
          ],
          locale: Locale(locale),
        );
        expect(find.byType(TextButton), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('teen task, proof sheet and milestone screens', (
        tester,
      ) async {
        _smallPhone(tester);
        final tasks = FakeTaskRepository([
          fakeTask(
            id: 'c1',
            title: 'Мектептен кейін ыдыс-аяқты жуып, орнына қою',
          ).copyWith(
            description: 'Өте ұзын сипаттама ' * 12,
            decisionNote: 'Қайта жасаңыз, ' * 10,
            penalty: const Money.kzt(50000),
          ),
        ]);
        tasks.onSubmit = () async => throw const ApiException(code: 'timeout');
        final dash = FakeDashboardRepository(
          fakeDashboard(
            milestones: [
              fakeMilestone(id: 'm1', approvedTasks: 1, totalTasks: 3),
            ],
            chores: [
              for (var i = 0; i < 3; i++)
                fakeChore(
                  id: 's$i',
                  title: 'Өте ұзын қадамның атауы нөмір $i',
                  milestoneId: 'm1',
                  state: i == 0 ? TaskState.approved : TaskState.assigned,
                ),
            ],
          ),
        );
        await pumpApp(
          tester,
          overrides: [
            authControllerProvider.overrideWith(() => _Auth(_teenUser)),
            familyControllerProvider.overrideWith(
              () => _Family(() async => _parents),
            ),
            dashboardRepositoryProvider.overrideWithValue(dash),
            payoutRepositoryProvider.overrideWithValue(FakePayoutRepository()),
            taskRepositoryProvider.overrideWithValue(tasks),
          ],
          locale: Locale(locale),
        );

        unawaited(routerOf(tester).push(Routes.teenMilestone('m1')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView).last, const Offset(0, -2000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        routerOf(tester).pop();
        await tester.pumpAndSettle();

        unawaited(routerOf(tester).push(Routes.teenTask('c1')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final submit = find.byType(FilledButton);
        await tester.scrollUntilVisible(
          submit,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Note path, long text, then the failure line and "Try again".
        final write = find.byType(TextButton).first;
        await tester.tap(write);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Ұзын жазба ' * 30);
        await tester.pump();
        await tester.tap(find.byType(FilledButton).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('parent task and milestone detail, cancel sheet', (
        tester,
      ) async {
        _smallPhone(tester);
        final long = 'Өте ұзын атау, сондай-ақ ұзын сөздер ' * 2;
        final tasks = FakeTaskRepository([
          fakeTask(
            id: 'm1',
            teenId: '4',
            kind: TaskKind.milestone,
            title: long,
          ).copyWith(
            description: 'Сипаттама ' * 30,
            decisionNote: 'Ескерту ' * 20,
            penalty: const Money.kzt(50000),
          ),
          for (var i = 0; i < 3; i++)
            fakeTask(
              id: 's$i',
              teenId: '4',
              title: '$long $i',
              milestoneId: 'm1',
            ),
        ]);
        await pumpApp(
          tester,
          overrides: [
            authControllerProvider.overrideWith(() => _Auth(_parentUser)),
            familyControllerProvider.overrideWith(
              () => _Family(() async => _teens),
            ),
            payoutRepositoryProvider.overrideWithValue(FakePayoutRepository()),
            taskRepositoryProvider.overrideWithValue(tasks),
          ],
          locale: Locale(locale),
        );

        unawaited(routerOf(tester).push(Routes.parentTask('4', 'm1')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final cancel = find.text(
          AppLocalizations.of(tester.element(find.byType(Scaffold).last))
              .parentCancelMilestone,
        );
        await tester.scrollUntilVisible(
          cancel,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(cancel);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      group('payouts:', () {
        List<Override> teen({
          Dashboard? dashboard,
          List<FamilyMember> parents = const [
            FamilyMember(
              id: '1',
              role: Role.parent,
              displayName: 'Айгерім Нұрланқызы',
            ),
          ],
          FakePayoutRepository? payouts,
          FakeDashboardRepository? dashboardRepo,
        }) => [
          authControllerProvider.overrideWith(() => _Auth(_teenUser)),
          familyControllerProvider.overrideWith(
            () => _Family(() async => parents),
          ),
          dashboardRepositoryProvider.overrideWithValue(
            dashboardRepo ?? FakeDashboardRepository(dashboard),
          ),
          payoutRepositoryProvider.overrideWithValue(
            payouts ?? FakePayoutRepository(),
          ),
        ];

        List<Override> parent(FakePayoutRepository payouts) => [
          authControllerProvider.overrideWith(() => _Auth(_parentUser)),
          familyControllerProvider.overrideWith(
            () => _Family(() async => _teens),
          ),
          payoutRepositoryProvider.overrideWithValue(payouts),
          taskRepositoryProvider.overrideWithValue(FakeTaskRepository()),
        ];

        Payout longPayout({
          String id = 'po1',
          String teenId = '4',
          PayoutState state = PayoutState.requested,
          CancelReason? reason,
        }) => fakePayout(
          id: id,
          teenId: teenId,
          parentId: '1',
          amount: const Money.kzt(1250000050),
          state: state,
          cancelReason: reason,
          requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
          expiresAt: DateTime.now().add(const Duration(days: 6, hours: 22)),
        );

        OpenPayout open() => OpenPayout(
          id: 'po1',
          parentId: '1',
          amount: const Money.kzt(1250000050),
          requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
          expiresAt: DateTime.now().add(const Duration(days: 6, hours: 4)),
        );

        Balance bal(int balance, int locked, int available) => Balance(
          balance: Money.kzt(balance),
          locked: Money.kzt(locked),
          available: Money.kzt(available),
        );

        Future<void> go(WidgetTester tester, String route) async {
          unawaited(routerOf(tester).push(route));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        Future<Finder> reach(
          WidgetTester tester,
          String Function(AppLocalizations l10n) label,
        ) async {
          final l10n = AppLocalizations.of(
            tester.element(find.byType(Scaffold).last),
          );
          final button = find.widgetWithText(BusyButton, label(l10n));
          await tester.scrollUntilVisible(
            button,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          return button;
        }

        testWidgets('teen home: every cash-out state', (tester) async {
          _smallPhone(tester);
          final states = <Dashboard>[
            fakeDashboard(
              balance: const Money.kzt(1250000050),
              available: const Money.kzt(1250000050),
            ),
            fakeDashboard(
              balance: const Money.kzt(3000),
              available: const Money.kzt(3000),
            ),
            fakeDashboard(
              balance: const Money.kzt(1500000),
              locked: const Money.kzt(1400000),
              available: const Money.kzt(100000),
            ),
            Dashboard(
              balance: bal(-250000, 0, -250000),
              pending: Money.zero,
              chores: const [],
              milestones: const [],
            ),
            fakeDashboard(openPayout: open()),
          ];
          final dashboard = FakeDashboardRepository(states.first);
          await pumpApp(
            tester,
            overrides: teen(dashboardRepo: dashboard),
            locale: Locale(locale),
          );
          for (final state in states) {
            dashboard.dashboard = state;
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, 400),
            );
            await tester.pump();
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        });

        testWidgets('request form, one parent: inputs and explanations', (
          tester,
        ) async {
          _smallPhone(tester);
          await pumpApp(
            tester,
            overrides: teen(
              dashboard: fakeDashboard(available: const Money.kzt(1250000)),
            ),
            locale: Locale(locale),
          );
          await go(tester, Routes.teenCashOut);
          final field = find.byType(TextField);
          for (final text in ['0', '10', '99999999', '5000']) {
            await tester.enterText(field, text);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        });

        testWidgets('request form, several parents: picker, ambiguous lock', (
          tester,
        ) async {
          _smallPhone(tester);
          final payouts = FakePayoutRepository()
            ..createError = const ApiException(code: 'timeout');
          await pumpApp(
            tester,
            overrides: teen(parents: _parents, payouts: payouts),
            locale: Locale(locale),
          );
          await go(tester, Routes.teenCashOut);
          expect(find.byType(RadioListTile<String>), findsNWidgets(2));
          await tester.enterText(find.byType(TextField), '5000');
          await tester.pumpAndSettle();
          await tester.tap(find.byType(RadioListTile<String>).last);
          await tester.pumpAndSettle();
          final send = find.byType(BusyButton);
          await tester.ensureVisible(send);
          await tester.pumpAndSettle();
          await tester.tap(send);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byType(TextButton), findsWidgets, reason: 'Edit details');
        });

        testWidgets('request form: already open and blocked', (tester) async {
          _smallPhone(tester);
          final payouts = FakePayoutRepository()
            ..createError = const ApiException(
              code: 'payout_already_open',
              statusCode: 409,
            );
          await pumpApp(
            tester,
            overrides: teen(payouts: payouts),
            locale: Locale(locale),
          );
          await go(tester, Routes.teenCashOut);
          await tester.enterText(find.byType(TextField), '5000');
          await tester.pumpAndSettle();
          final send = find.byType(BusyButton);
          await tester.ensureVisible(send);
          await tester.tap(send);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });

        testWidgets('teen payout screen: open card and cancel sheet', (
          tester,
        ) async {
          _smallPhone(tester);
          final payouts = FakePayoutRepository([longPayout(teenId: '2')]);
          await pumpApp(
            tester,
            overrides: teen(
              dashboard: fakeDashboard(openPayout: open()),
              payouts: payouts,
            ),
            locale: Locale(locale),
          );
          await go(tester, Routes.teenPayout('po1'));
          final cancel = find.byType(BusyButton);
          await tester.ensureVisible(cancel);
          await tester.tap(cancel);
          await tester.pumpAndSettle();
          expect(find.byType(BottomSheet), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('teen payout screen: every outcome, missing, error', (
          tester,
        ) async {
          _smallPhone(tester);
          final payouts = FakePayoutRepository([
            longPayout(id: 'f', teenId: '2', state: PayoutState.fulfilled),
            longPayout(
              id: 'd',
              teenId: '2',
              state: PayoutState.cancelled,
              reason: CancelReason.declined,
            ),
            longPayout(
              id: 'e',
              teenId: '2',
              state: PayoutState.cancelled,
              reason: CancelReason.expired,
            ),
            longPayout(
              id: 'c',
              teenId: '2',
              state: PayoutState.cancelled,
              reason: CancelReason.teenCancelled,
            ),
            longPayout(
              id: 'u',
              teenId: '2',
              state: PayoutState.cancelled,
              reason: CancelReason.unlinked,
            ),
          ]);
          await pumpApp(
            tester,
            overrides: teen(payouts: payouts),
            locale: Locale(locale),
          );
          for (final id in ['f', 'd', 'e', 'c', 'u', 'missing']) {
            await go(tester, Routes.teenPayout(id));
            routerOf(tester).pop();
            await tester.pumpAndSettle();
          }
          payouts.getError = const ApiException(code: 'network_error');
          await go(tester, Routes.teenPayout('f'));
        });

        testWidgets('parent: requests section with long names', (tester) async {
          _smallPhone(tester);
          final payouts = FakePayoutRepository([
            longPayout(id: 'a', teenId: '2'),
            longPayout(id: 'b', teenId: '3'),
            longPayout(id: 'c', teenId: '4'),
          ]);
          await pumpApp(
            tester,
            overrides: parent(payouts),
            locale: Locale(locale),
          );
          await tester.tap(find.byIcon(Icons.task_alt));
          await tester.pumpAndSettle();
          expect(find.byType(Badge), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('parent: requests section loading and error', (
          tester,
        ) async {
          _smallPhone(tester);
          final payouts = FakePayoutRepository()
            ..listError = const ApiException(code: 'network_error');
          await pumpApp(
            tester,
            overrides: parent(payouts),
            locale: Locale(locale),
          );
          await tester.tap(find.byIcon(Icons.task_alt));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });

        testWidgets('parent payout screen: sheets and every state', (
          tester,
        ) async {
          _smallPhone(tester);
          final payouts = FakePayoutRepository([longPayout()])
            ..fulfilError = const ApiException(
              code: 'insufficient_funds',
              statusCode: 422,
            );
          await pumpApp(
            tester,
            overrides: parent(payouts),
            locale: Locale(locale),
          );
          await go(tester, Routes.parentPayout('po1'));

          // Decline sheet, then close it without declining.
          await tester.tap(await reach(tester, (l) => l.payoutDecline));
          await tester.pumpAndSettle();
          expect(find.byType(BottomSheet), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(
            find.descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(FilledButton),
            ),
          );
          await tester.pumpAndSettle();

          // Confirm-sent sheet, confirm, then the insufficient-funds card.
          await tester.tap(await reach(tester, (l) => l.payoutISentIt));
          await tester.pumpAndSettle();
          expect(find.byType(BottomSheet), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(
            find.descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(FilledButton),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Outcomes, missing and a failed load.
          payouts.payouts = [
            longPayout(id: 'f', state: PayoutState.fulfilled),
            longPayout(
              id: 'd',
              state: PayoutState.cancelled,
              reason: CancelReason.declined,
            ),
            longPayout(
              id: 'c',
              state: PayoutState.cancelled,
              reason: CancelReason.teenCancelled,
            ),
          ];
          routerOf(tester).pop();
          await tester.pumpAndSettle();
          for (final id in ['f', 'd', 'c', 'missing']) {
            await go(tester, Routes.parentPayout(id));
            routerOf(tester).pop();
            await tester.pumpAndSettle();
          }
          payouts.getError = const ApiException(code: 'network_error');
          await go(tester, Routes.parentPayout('f'));
        });

        testWidgets('parent payout screen: not linked and bank notes', (
          tester,
        ) async {
          _smallPhone(tester);
          final payouts = FakePayoutRepository([longPayout()])
            ..fulfilError = const ApiException(
              code: 'forbidden',
              statusCode: 403,
            );
          await pumpApp(
            tester,
            overrides: [
              ...parent(payouts),
              bankLauncherProvider.overrideWithValue(
                FakeBankLauncher(BankLaunchResult.unavailable),
              ),
            ],
            locale: Locale(locale),
          );
          await go(tester, Routes.parentPayout('po1'));
          final bank = find.byType(FilledButton).first;
          await tester.ensureVisible(bank);
          await tester.tap(bank);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tester.tap(await reach(tester, (l) => l.payoutISentIt));
          await tester.pumpAndSettle();
          await tester.tap(
            find.descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(FilledButton),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
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
