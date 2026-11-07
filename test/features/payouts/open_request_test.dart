import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/app/app.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/money/money_format.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';
import 'package:tiyn_app/features/payouts/application/payout_providers.dart';
import 'package:tiyn_app/features/payouts/data/cancel_reason.dart';
import 'package:tiyn_app/features/payouts/data/payout_state.dart';
import 'package:tiyn_app/features/teen/application/dashboard_controller.dart';
import 'package:tiyn_app/features/teen/data/dashboard.dart';

import '../../helpers/fake_dashboard.dart';
import '../../helpers/fake_family.dart';
import '../../helpers/fake_payouts.dart';
import '../../helpers/pump_app.dart';

class _TeenAuth extends AuthController {
  @override
  Future<User?> build() async =>
      const User(id: 'teen1', role: Role.teen, displayName: 'Dana');
}

String _money(int minor) => formatMoney(Money.kzt(minor), locale: 'en');

OpenPayout _open({String parentId = 'p1', Duration? left}) => OpenPayout(
  id: 'po1',
  parentId: parentId,
  amount: const Money.kzt(500000),
  requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
  // Margin so "6 days" survives the milliseconds a test takes.
  expiresAt: DateTime.now().add(left ?? const Duration(days: 6, hours: 4)),
);

class _Harness {
  _Harness({Dashboard? dashboard, List<FamilyMember>? parents})
    : dashboard = FakeDashboardRepository(dashboard),
      family = FakeFamilyRepository(
        parents ??
            const [
              FamilyMember(id: 'p1', role: Role.parent, displayName: 'Aigerim'),
            ],
      ),
      payouts = FakePayoutRepository();

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

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(TiynApp)));

Finder get _cancelButton =>
    find.widgetWithText(OutlinedButton, 'Cancel request');

void main() {
  group('the card on home', () {
    testWidgets('replaces the button and shows who, what is held, the time', (
      tester,
    ) async {
      final h = _Harness(dashboard: fakeDashboard(openPayout: _open()));
      await pumpApp(tester, overrides: h.overrides);

      expect(find.widgetWithText(FilledButton, 'Cash out'), findsNothing);
      expect(find.text('Waiting for Aigerim'), findsOneWidget);
      expect(
        find.text('${_money(500000)} held for this request'),
        findsOneWidget,
      );
      expect(find.text('6 days left'), findsOneWidget);
      expect(_cancelButton, findsOneWidget);
    });

    for (final (left, label) in [
      (const Duration(hours: 5, minutes: 30), '5 hours left'),
      (const Duration(minutes: 20), 'Less than an hour left'),
      (const Duration(minutes: -2), 'Expires any moment'),
    ]) {
      testWidgets('the time label reads "$label"', (tester) async {
        final h = _Harness(
          dashboard: fakeDashboard(openPayout: _open(left: left)),
        );
        await pumpApp(tester, overrides: h.overrides);
        expect(find.text(label), findsOneWidget);
      });
    }

    testWidgets('a parent who is not in the family list gets a plain label', (
      tester,
    ) async {
      final h = _Harness(
        dashboard: fakeDashboard(openPayout: _open(parentId: 'gone')),
        parents: const [
          FamilyMember(id: 'p1', role: Role.parent, displayName: 'Aigerim'),
        ],
      );
      await pumpApp(tester, overrides: h.overrides);
      expect(find.text('Waiting for your parent'), findsOneWidget);
    });

    testWidgets('disappears when a refreshed dashboard has no request', (
      tester,
    ) async {
      final h = _Harness(dashboard: fakeDashboard(openPayout: _open()));
      await pumpApp(tester, overrides: h.overrides);
      expect(_cancelButton, findsOneWidget);

      // What a PAYOUT_DECLINED push does.
      h.dashboard.dashboard = fakeDashboard();
      await _container(tester)
          .read(dashboardControllerProvider.notifier)
          .refresh();
      await tester.pumpAndSettle();

      expect(_cancelButton, findsNothing);
      expect(find.widgetWithText(FilledButton, 'Cash out'), findsOneWidget);
    });
  });

  group('cancel', () {
    testWidgets(
      'needs a confirmation that names the amount; Keep does nothing',
      (tester) async {
        final h = _Harness(dashboard: fakeDashboard(openPayout: _open()));
        await pumpApp(tester, overrides: h.overrides);

        await tester.tap(_cancelButton);
        await tester.pumpAndSettle();
        expect(find.text('Cancel this request?'), findsOneWidget);
        expect(
          find.textContaining(_money(500000)),
          findsWidgets,
          reason: 'the sheet names the amount',
        );
        expect(h.payouts.cancels, isEmpty, reason: 'not before confirming');

        await tester.tap(find.text('Keep it'));
        await tester.pumpAndSettle();
        expect(h.payouts.cancels, isEmpty);
        expect(_cancelButton, findsOneWidget);
      },
    );

    testWidgets('confirming cancels once and refreshes the dashboard', (
      tester,
    ) async {
      final h = _Harness(dashboard: fakeDashboard(openPayout: _open()));
      h.payouts.cancelGate = Completer<void>();
      await pumpApp(tester, overrides: h.overrides);
      final before = h.dashboard.calls;

      await tester.tap(_cancelButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, cancel the request'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      h.dashboard.dashboard = fakeDashboard();
      h.payouts.cancelGate!.complete();
      await tester.pumpAndSettle();

      expect(h.payouts.cancels, ['po1']);
      expect(h.dashboard.calls, before + 1);
      expect(_cancelButton, findsNothing);
      expect(find.widgetWithText(FilledButton, 'Cash out'), findsOneWidget);
    });

    testWidgets('leaving the screen mid-cancel still clears the card', (
      tester,
    ) async {
      final h = _Harness(dashboard: fakeDashboard(openPayout: _open()));
      h.payouts.payouts = [fakePayout()];
      h.payouts.cancelGate = Completer<void>();
      await pumpApp(tester, overrides: h.overrides);
      routerOf(tester).go('/teen/home/payout/po1');
      await tester.pumpAndSettle();
      final before = h.dashboard.calls;

      await tester.tap(_cancelButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, cancel the request'));
      await tester.pump();
      await tester.pump();
      routerOf(tester).go('/teen/home');
      await tester.pumpAndSettle();

      h.dashboard.dashboard = fakeDashboard();
      h.payouts.cancelGate!.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(h.payouts.cancels, ['po1']);
      expect(h.dashboard.calls, greaterThan(before));
      expect(_cancelButton, findsNothing);
    });

    testWidgets('409 invalid_transition says it changed and refreshes', (
      tester,
    ) async {
      final h = _Harness(dashboard: fakeDashboard(openPayout: _open()));
      h.payouts.cancelError = const ApiException(
        code: 'invalid_transition',
        statusCode: 409,
      );
      await pumpApp(tester, overrides: h.overrides);
      final before = h.dashboard.calls;

      // The parent declined meanwhile.
      h.dashboard.dashboard = fakeDashboard();
      await tester.tap(_cancelButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, cancel the request'));
      await tester.pumpAndSettle();

      expect(
        find.text('This request just changed. Here is the latest.'),
        findsOneWidget,
      );
      expect(h.dashboard.calls, before + 1);
      expect(_cancelButton, findsNothing);
    });

    testWidgets('another failure shows its plain message and keeps the card', (
      tester,
    ) async {
      final h = _Harness(dashboard: fakeDashboard(openPayout: _open()));
      h.payouts.cancelError = const ApiException(code: 'network_error');
      await pumpApp(tester, overrides: h.overrides);

      await tester.tap(_cancelButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, cancel the request'));
      await tester.pumpAndSettle();

      expect(find.text('No connection. Check your network.'), findsOneWidget);
      expect(_cancelButton, findsOneWidget);
    });
  });

  group('the payout screen', () {
    Future<_Harness> open(
      WidgetTester tester, {
      PayoutState state = PayoutState.requested,
      CancelReason? reason,
      bool known = true,
    }) async {
      final h = _Harness(dashboard: fakeDashboard());
      if (known) {
        h.payouts.payouts = [
          fakePayout(
            state: state,
            cancelReason: reason,
            expiresAt: DateTime.now().add(const Duration(days: 3, hours: 2)),
          ),
        ];
      }
      await pumpApp(tester, overrides: h.overrides);
      routerOf(tester).go('/teen/home/payout/po1');
      await tester.pumpAndSettle();
      return h;
    }

    testWidgets('a request still open shows the card with Cancel', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('Waiting for Aigerim'), findsOneWidget);
      expect(find.text('3 days left'), findsOneWidget);
      expect(_cancelButton, findsOneWidget);
    });

    testWidgets('cancelling from here shows the cancelled outcome', (
      tester,
    ) async {
      final h = await open(tester);
      h.payouts.payouts = [
        fakePayout(
          state: PayoutState.cancelled,
          cancelReason: CancelReason.teenCancelled,
        ),
      ];
      await tester.tap(_cancelButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, cancel the request'));
      await tester.pumpAndSettle();
      expect(find.text('Request cancelled'), findsOneWidget);
      expect(_cancelButton, findsNothing);
    });

    testWidgets('fulfilled', (tester) async {
      await open(tester, state: PayoutState.fulfilled);
      expect(
        find.text('Payout of ${_money(500000)} confirmed'),
        findsOneWidget,
      );
      expect(find.textContaining('Check your bank'), findsOneWidget);
      expect(_cancelButton, findsNothing);
    });

    for (final (reason, title) in [
      (CancelReason.declined, 'Request declined'),
      (CancelReason.expired, 'Request expired'),
      (CancelReason.teenCancelled, 'Request cancelled'),
      (CancelReason.unlinked, 'No longer linked'),
    ]) {
      testWidgets('cancelled: ${reason.wire}', (tester) async {
        await open(tester, state: PayoutState.cancelled, reason: reason);
        expect(find.text(title), findsOneWidget);
        expect(
          find.textContaining(_money(500000)),
          findsOneWidget,
          reason: 'the money is available again',
        );
        expect(_cancelButton, findsNothing);
      });
    }

    testWidgets('an unknown payout (404) says it is not available', (
      tester,
    ) async {
      await open(tester, known: false);
      expect(find.text('This request is no longer available.'), findsOneWidget);
    });

    testWidgets('403 (link gone) says not available too', (tester) async {
      final h = _Harness(dashboard: fakeDashboard());
      h.payouts.getError = const ApiException(
        code: 'forbidden',
        statusCode: 403,
      );
      await pumpApp(tester, overrides: h.overrides);
      routerOf(tester).go('/teen/home/payout/po1');
      await tester.pumpAndSettle();
      expect(find.text('This request is no longer available.'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('a network failure offers Try again', (tester) async {
      final h = _Harness(dashboard: fakeDashboard());
      h.payouts.getError = const ApiException(code: 'network_error');
      await pumpApp(tester, overrides: h.overrides);
      routerOf(tester).go('/teen/home/payout/po1');
      await tester.pumpAndSettle();
      expect(find.text('No connection. Check your network.'), findsOneWidget);

      h.payouts
        ..getError = null
        ..payouts = [fakePayout(state: PayoutState.fulfilled)];
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.textContaining('confirmed'), findsWidgets);
    });
  });
}
