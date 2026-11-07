import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiyn_app/app/app.dart';
import 'package:tiyn_app/app/config.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/push/push_messaging.dart';
import 'package:tiyn_app/core/push/push_providers.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';
import 'package:tiyn_app/features/payouts/application/payout_providers.dart';
import 'package:tiyn_app/features/payouts/data/payout_state.dart';
import 'package:tiyn_app/features/payouts/presentation/open_request_card.dart';
import 'package:tiyn_app/features/push/application/device_registration.dart';
import 'package:tiyn_app/features/teen/application/dashboard_controller.dart';
import 'package:tiyn_app/features/teen/data/dashboard.dart';

import '../../helpers/fake_dashboard.dart';
import '../../helpers/fake_family.dart';
import '../../helpers/fake_payouts.dart';
import '../../helpers/fake_push_backend.dart';
import '../../helpers/fake_push_messaging.dart';
import '../../helpers/parent_harness.dart';
import '../../helpers/pump_app.dart';

const _parentUser = User(
  id: 'parent1',
  role: Role.parent,
  displayName: 'Aigerim',
);

class _TeenAuth extends AuthController {
  @override
  Future<User?> build() async =>
      const User(id: 'teen1', role: Role.teen, displayName: 'Dana');
}

class _GatedParentAuth extends AuthController {
  _GatedParentAuth(this._gate);

  final Future<void> _gate;

  @override
  Future<User?> build() async {
    await _gate;
    return _parentUser;
  }
}

List<Override> _push(FakePushMessaging push) => [
  pushMessagingProvider.overrideWithValue(push),
  pushStoreProvider.overrideWithValue(FakePushStore()),
  deviceRepositoryProvider.overrideWithValue(FakeDeviceRepository()),
];

PushMessage _tap(String type, [String? payoutId]) =>
    PushMessage(data: {'type': type, 'payoutId': ?payoutId});

String _at(WidgetTester tester) => routerOf(tester).state.matchedLocation;

OpenPayout _open() => OpenPayout(
  id: 'po1',
  parentId: 'p1',
  amount: const Money.kzt(500000),
  requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
  expiresAt: DateTime.now().add(const Duration(days: 6, hours: 4)),
);

class _Teen {
  _Teen()
    : dashboard = FakeDashboardRepository(fakeDashboard(openPayout: _open())),
      family = FakeFamilyRepository(const [
        FamilyMember(id: 'p1', role: Role.parent, displayName: 'Aigerim'),
      ]),
      payouts = FakePayoutRepository([fakePayout()]);

  final FakeDashboardRepository dashboard;
  final FakeFamilyRepository family;
  final FakePayoutRepository payouts;

  List<Override> get overrides => [
    authControllerProvider.overrideWith(_TeenAuth.new),
    familyRepositoryProvider.overrideWithValue(family),
    dashboardRepositoryProvider.overrideWithValue(dashboard),
    payoutRepositoryProvider.overrideWithValue(payouts),
  ];
}

Future<void> _pumpNoSettle(
  WidgetTester tester,
  List<Override> overrides,
) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig(
            flavor: Flavor.staging,
            apiBaseUrl: Uri.parse('https://api.test'),
            googleServerClientId: null,
          ),
        ),
        ...overrides,
      ],
      child: const TiynApp(locale: Locale('en')),
    ),
  );
  await tester.pump();
}

void main() {
  group('parent', () {
    testWidgets('warm tap on PAYOUT_REQUESTED opens it; back is To check', (
      tester,
    ) async {
      final push = FakePushMessaging();
      final h = ParentHarness(teens: [(id: 'teen1', name: 'Dana')]);
      h.payouts.payouts = [fakePayout(teenId: 'teen1')];
      await pumpApp(tester, overrides: [...h.overrides, ..._push(push)]);
      expect(_at(tester), '/parent/home');

      push.emitOpened(_tap('PAYOUT_REQUESTED', 'po1'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(_at(tester), '/parent/review/payout/po1');

      routerOf(tester).pop();
      await tester.pumpAndSettle();
      expect(_at(tester), '/parent/review');
    });

    testWidgets('PAYOUT_CANCELLED_BY_TEEN opens the payout too', (
      tester,
    ) async {
      final push = FakePushMessaging();
      final h = ParentHarness(teens: [(id: 'teen1', name: 'Dana')]);
      await pumpApp(tester, overrides: [...h.overrides, ..._push(push)]);

      push.emitOpened(_tap('PAYOUT_CANCELLED_BY_TEEN', 'po1'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(_at(tester), '/parent/review/payout/po1');
    });

    testWidgets('a payout push for the teen, or with no id, lands on home', (
      tester,
    ) async {
      final push = FakePushMessaging();
      final h = ParentHarness(teens: [(id: 'teen1', name: 'Dana')]);
      await pumpApp(tester, overrides: [...h.overrides, ..._push(push)]);

      for (final m in [
        _tap('PAYOUT_FULFILLED', 'po1'),
        _tap('PAYOUT_REQUESTED'),
        _tap('PAYOUT_REQUESTED', '  '),
      ]) {
        push.emitOpened(m);
        await tester.pump();
        await tester.pumpAndSettle();
        expect(_at(tester), '/parent/home');
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('cold start goes through splash, back is To check', (
      tester,
    ) async {
      final gate = Completer<void>();
      final push = FakePushMessaging()
        ..initial = _tap('PAYOUT_REQUESTED', 'po1');
      final h = ParentHarness(teens: [(id: 'teen1', name: 'Dana')]);
      h.payouts.payouts = [fakePayout(teenId: 'teen1')];
      await _pumpNoSettle(tester, [
        ...h.overrides.skip(1),
        authControllerProvider.overrideWith(
          () => _GatedParentAuth(gate.future),
        ),
        ..._push(push),
      ]);
      expect(_at(tester), '/splash');

      gate.complete();
      await tester.pumpAndSettle();
      expect(_at(tester), '/parent/review/payout/po1');

      routerOf(tester).pop();
      await tester.pumpAndSettle();
      expect(_at(tester), '/parent/review');
    });

    testWidgets('a PAYOUT_REQUESTED push adds the badge with no pull', (
      tester,
    ) async {
      final push = FakePushMessaging();
      final h = ParentHarness(teens: [(id: 'teen1', name: 'Dana')]);
      await pumpApp(tester, overrides: [...h.overrides, ..._push(push)]);
      expect(find.byType(Badge), findsNothing);
      final before = h.payouts.listStates.length;

      h.payouts.payouts = [fakePayout(teenId: 'teen1')];
      push.emitForeground(
        const PushMessage(
          title: 'Cash-out',
          data: {'type': 'PAYOUT_REQUESTED', 'payoutId': 'po1'},
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(h.payouts.listStates.length, greaterThan(before));
      expect(
        find.descendant(of: find.byType(Badge), matching: find.text('1')),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 6));
    });
  });

  group('teen', () {
    testWidgets('warm tap on PAYOUT_FULFILLED opens it; back is home', (
      tester,
    ) async {
      final push = FakePushMessaging();
      final h = _Teen();
      h.payouts.payouts = [fakePayout(state: PayoutState.fulfilled)];
      await pumpApp(tester, overrides: [...h.overrides, ..._push(push)]);

      push.emitOpened(_tap('PAYOUT_FULFILLED', 'po1'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(_at(tester), '/teen/home/payout/po1');

      routerOf(tester).pop();
      await tester.pumpAndSettle();
      expect(_at(tester), '/teen/home');
    });

    testWidgets('a parent-only payout push lands on home', (tester) async {
      final push = FakePushMessaging();
      final h = _Teen();
      await pumpApp(tester, overrides: [...h.overrides, ..._push(push)]);

      push.emitOpened(_tap('PAYOUT_REQUESTED', 'po1'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(_at(tester), '/teen/home');
    });

    testWidgets(
      'a PAYOUT_FULFILLED push drops the card and the coin with no pull',
      (tester) async {
        final push = FakePushMessaging();
        final h = _Teen();
        await pumpApp(tester, overrides: [...h.overrides, ..._push(push)]);
        expect(find.byType(OpenRequestCard), findsOneWidget);
        final family = h.family.calls;

        h.dashboard.dashboard = fakeDashboard(
          balance: const Money.kzt(1000000),
          available: const Money.kzt(750000),
        );
        push.emitForeground(
          const PushMessage(
            title: 'Paid',
            data: {'type': 'PAYOUT_FULFILLED', 'payoutId': 'po1'},
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();

        expect(find.byType(OpenRequestCard), findsNothing);
        expect(h.family.calls, family, reason: 'family is not reloaded');
        expect(_at(tester), '/teen/home', reason: 'no splash');
        await tester.pump(const Duration(seconds: 6));
      },
    );

    testWidgets('an open outcome screen updates when the push arrives', (
      tester,
    ) async {
      final push = FakePushMessaging();
      final h = _Teen();
      await pumpApp(tester, overrides: [...h.overrides, ..._push(push)]);
      routerOf(tester).go('/teen/home/payout/po1');
      await tester.pumpAndSettle();
      expect(find.byType(OpenRequestCard), findsOneWidget);

      h.payouts.payouts = [fakePayout(state: PayoutState.fulfilled)];
      h.dashboard.dashboard = fakeDashboard();
      push.emitForeground(
        const PushMessage(
          title: 'Paid',
          data: {'type': 'PAYOUT_FULFILLED', 'payoutId': 'po1'},
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(OpenRequestCard), findsNothing);
      await tester.pump(const Duration(seconds: 6));
    });
  });
}
