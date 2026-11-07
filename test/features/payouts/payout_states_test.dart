import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';
import 'package:tiyn_app/features/payouts/application/payout_providers.dart';
import 'package:tiyn_app/features/payouts/data/payout_state.dart';
import 'package:tiyn_app/features/teen/application/dashboard_controller.dart';
import 'package:tiyn_app/features/teen/data/dashboard.dart';

import '../../helpers/fake_dashboard.dart';
import '../../helpers/fake_family.dart';
import '../../helpers/fake_payouts.dart';
import '../../helpers/parent_harness.dart';
import '../../helpers/pump_app.dart';

class _TeenAuth extends AuthController {
  @override
  Future<User?> build() async =>
      const User(id: 'teen1', role: Role.teen, displayName: 'Dana');
}

OpenPayout _open() => OpenPayout(
  id: 'po1',
  parentId: 'p1',
  amount: const Money.kzt(500000),
  requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
  expiresAt: DateTime.now().add(const Duration(days: 6, hours: 4)),
);

List<Override> _teen(FakePayoutRepository payouts, {Dashboard? dashboard}) => [
  authControllerProvider.overrideWith(_TeenAuth.new),
  familyRepositoryProvider.overrideWithValue(
    FakeFamilyRepository(const [
      FamilyMember(id: 'p1', role: Role.parent, displayName: 'Aigerim'),
    ]),
  ),
  dashboardRepositoryProvider.overrideWithValue(
    FakeDashboardRepository(dashboard),
  ),
  payoutRepositoryProvider.overrideWithValue(payouts),
];

Future<void> _openToCheck(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('To check'),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('loading', () {
    testWidgets('parent: the requests section shows a spinner, then rows', (
      tester,
    ) async {
      final h = ParentHarness(teens: [(id: 'teen1', name: 'Dana')]);
      final payouts = h.payouts
        ..payouts = [fakePayout(teenId: 'teen1')]
        ..listGate = Completer<void>();
      await pumpAppNoSettle(tester, overrides: h.overrides);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await _openToCheck(tester);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('Cash-out request'), findsNothing);

      payouts.listGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Cash-out request'), findsOneWidget);
    });

    testWidgets('parent: the payout screen shows a spinner, then the request', (
      tester,
    ) async {
      final h = ParentHarness(teens: [(id: 'teen1', name: 'Dana')]);
      final payouts = h.payouts..payouts = [fakePayout(teenId: 'teen1')];
      await pumpApp(tester, overrides: h.overrides);
      payouts.getGate = Completer<void>();
      unawaited(routerOf(tester).push('/parent/review/payout/po1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Dana asks for'), findsNothing);

      payouts.getGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Dana asks for'), findsOneWidget);
    });

    testWidgets('teen: the payout screen shows a spinner, then the outcome', (
      tester,
    ) async {
      final payouts = FakePayoutRepository([
        fakePayout(state: PayoutState.fulfilled),
      ]);
      await pumpApp(tester, overrides: _teen(payouts));
      payouts.getGate = Completer<void>();
      unawaited(routerOf(tester).push('/teen/home/payout/po1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      payouts.getGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('error', () {
    testWidgets('parent: a failing payout screen offers Try again', (
      tester,
    ) async {
      final h = ParentHarness(teens: [(id: 'teen1', name: 'Dana')]);
      h.payouts.getError = const ApiException(code: 'network_error');
      await pumpApp(tester, overrides: h.overrides);
      unawaited(routerOf(tester).push('/parent/review/payout/po1'));
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsOneWidget);

      h.payouts
        ..getError = null
        ..payouts = [fakePayout(teenId: 'teen1')];
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Dana asks for'), findsOneWidget);
    });

    testWidgets('teen: a failing payout screen offers Try again', (
      tester,
    ) async {
      final payouts = FakePayoutRepository([
        fakePayout(state: PayoutState.fulfilled),
      ])..getError = const ApiException(code: 'network_error');
      await pumpApp(tester, overrides: _teen(payouts));
      unawaited(routerOf(tester).push('/teen/home/payout/po1'));
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsOneWidget);

      payouts.getError = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsNothing);
    });
  });

  group('empty', () {
    testWidgets('parent: no requests means no section and no badge', (
      tester,
    ) async {
      final h = ParentHarness(teens: [(id: 'teen1', name: 'Dana')]);
      await pumpApp(tester, overrides: h.overrides);
      await _openToCheck(tester);
      await tester.pumpAndSettle();
      expect(find.textContaining('Payout requests'), findsNothing);
      expect(find.byType(Badge), findsNothing);
    });
  });

  group('semantics', () {
    testWidgets('parent payout screen: headings, labelled and large targets', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final h = ParentHarness(teens: [(id: 'teen1', name: 'Dana')]);
      h.payouts.payouts = [fakePayout(teenId: 'teen1')];
      await pumpApp(tester, overrides: h.overrides);
      unawaited(routerOf(tester).push('/parent/review/payout/po1'));
      await tester.pumpAndSettle();

      for (final heading in ['1. Send the money', '2. Then confirm']) {
        expect(
          tester.getSemantics(find.text(heading)),
          isSemantics(isHeader: true),
          reason: heading,
        );
      }
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('parent: the request row and the badge are announced', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final h = ParentHarness(teens: [(id: 'teen1', name: 'Dana')]);
      h.payouts.payouts = [fakePayout(teenId: 'teen1')];
      await pumpApp(tester, overrides: h.overrides);
      expect(find.bySemanticsLabel(RegExp('1')), findsWidgets);
      await _openToCheck(tester);
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.textContaining('Payout requests')),
        isSemantics(isHeader: true),
      );
      expect(
        tester.getSemantics(find.text('Cash-out request')),
        isSemantics(hasTapAction: true),
      );
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('teen: the open-request card has a heading and big targets', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final payouts = FakePayoutRepository([fakePayout()]);
      await pumpApp(
        tester,
        overrides: _teen(
          payouts,
          dashboard: fakeDashboard(openPayout: _open()),
        ),
      );
      expect(
        tester.getSemantics(find.textContaining('Waiting for')),
        isSemantics(isHeader: true),
      );
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('teen: the request form is labelled with big targets', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, overrides: _teen(FakePayoutRepository()));
      unawaited(routerOf(tester).push('/teen/home/cash-out'));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });
}
