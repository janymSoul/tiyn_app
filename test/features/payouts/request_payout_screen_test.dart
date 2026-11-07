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

const _aigerim = FamilyMember(
  id: 'p1',
  role: Role.parent,
  displayName: 'Aigerim',
);
const _dauren = FamilyMember(
  id: 'p2',
  role: Role.parent,
  displayName: 'Dauren',
);

class _Harness {
  _Harness({
    Dashboard? dashboard,
    List<FamilyMember> parents = const [_aigerim],
  }) : dashboard = FakeDashboardRepository(dashboard),
       family = FakeFamilyRepository(parents),
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

String _money(int minor) => formatMoney(Money.kzt(minor), locale: 'en');

/// Rich enough for a 5 000 ₸ request: 10 000 ₸ available.
Dashboard _rich() => fakeDashboard(
  balance: const Money.kzt(1000000),
  locked: Money.zero,
  available: const Money.kzt(1000000),
);

Future<void> _open(WidgetTester tester, _Harness h) async {
  await pumpApp(tester, overrides: h.overrides);
  await tester.tap(find.widgetWithText(FilledButton, 'Cash out'));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String amount) async {
  await tester.enterText(find.byType(TextField), amount);
  await tester.pump();
}

Finder get _send => find.widgetWithText(FilledButton, 'Send request');

bool _enabled(WidgetTester tester, Finder button) =>
    tester.widget<FilledButton>(button).onPressed != null;

void main() {
  group('the Cash out button on home', () {
    testWidgets('opens the form when the teen can cash out', (tester) async {
      final h = _Harness(dashboard: _rich());
      await _open(tester, h);
      expect(routerOf(tester).state.matchedLocation, '/teen/home/cash-out');
      expect(find.text('Available: ${_money(1000000)}'), findsOneWidget);
    });

    testWidgets('a negative balance disables it and explains the debt', (
      tester,
    ) async {
      final h = _Harness(
        dashboard: fakeDashboard(
          balance: const Money.kzt(-250000),
          locked: Money.zero,
          available: const Money.kzt(-250000),
        ),
      );
      await pumpApp(tester, overrides: h.overrides);
      expect(
        _enabled(tester, find.widgetWithText(FilledButton, 'Cash out')),
        isFalse,
      );
      expect(
        find.text(
          'You owe ${_money(250000)} for a missed task. New rewards pay it '
          'off first, then you can cash out.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('below the minimum says so, without a goals line', (
      tester,
    ) async {
      final h = _Harness(
        dashboard: fakeDashboard(
          balance: const Money.kzt(5000),
          locked: Money.zero,
          available: const Money.kzt(5000),
        ),
      );
      await pumpApp(tester, overrides: h.overrides);
      expect(
        _enabled(tester, find.widgetWithText(FilledButton, 'Cash out')),
        isFalse,
      );
      expect(
        find.text('You need at least ${_money(10000)} available to cash out.'),
        findsOneWidget,
      );
      expect(find.textContaining('set aside for goals'), findsNothing);
    });

    testWidgets('the goals line shows only when money is locked', (
      tester,
    ) async {
      final h = _Harness(
        dashboard: fakeDashboard(
          balance: const Money.kzt(500000),
          locked: const Money.kzt(495000),
          available: const Money.kzt(5000),
        ),
      );
      await pumpApp(tester, overrides: h.overrides);
      expect(find.textContaining('set aside for goals'), findsOneWidget);
    });

    testWidgets('is not shown while a request is open', (tester) async {
      final h = _Harness(
        dashboard: fakeDashboard(
          openPayout: OpenPayout(
            id: 'po1',
            parentId: 'p1',
            amount: const Money.kzt(500000),
            requestedAt: DateTime.utc(2026, 11, 7),
            expiresAt: DateTime.utc(2026, 11, 14),
          ),
        ),
      );
      await pumpApp(tester, overrides: h.overrides);
      expect(find.widgetWithText(FilledButton, 'Cash out'), findsNothing);
    });
  });

  group('parent choice', () {
    testWidgets('one parent: no picker, sent to that parent', (tester) async {
      final h = _Harness(dashboard: _rich());
      await _open(tester, h);
      expect(find.text('To: Aigerim'), findsOneWidget);
      expect(find.byType(RadioListTile<String>), findsNothing);

      await _type(tester, '5000');
      await tester.tap(_send);
      await tester.pumpAndSettle();
      expect(h.payouts.creates.single.parentId, 'p1');
      expect(h.payouts.creates.single.amount, const Money.kzt(500000));
    });

    testWidgets('several parents: nothing preselected, Send waits for a pick', (
      tester,
    ) async {
      final h = _Harness(dashboard: _rich(), parents: [_aigerim, _dauren]);
      await _open(tester, h);
      expect(find.byType(RadioListTile<String>), findsNWidgets(2));
      await _type(tester, '5000');
      expect(_enabled(tester, _send), isFalse);

      await tester.tap(find.text('Dauren'));
      await tester.pump();
      expect(_enabled(tester, _send), isTrue);
      await tester.tap(_send);
      await tester.pumpAndSettle();
      expect(h.payouts.creates.single.parentId, 'p2');
    });
  });

  group('validation', () {
    testWidgets('Send is disabled until the amount is valid, with a reason', (
      tester,
    ) async {
      final h = _Harness(dashboard: _rich());
      await _open(tester, h);
      expect(_enabled(tester, _send), isFalse);
      expect(find.text('Smallest cash-out: ${_money(10000)}'), findsOneWidget);

      await _type(tester, '50');
      expect(
        find.text('The smallest cash-out is ${_money(10000)}.'),
        findsOneWidget,
      );
      expect(_enabled(tester, _send), isFalse);

      await _type(tester, '10 000,01');
      expect(
        find.text('You have ${_money(1000000)} available.'),
        findsOneWidget,
      );
      expect(_enabled(tester, _send), isFalse);

      await _type(tester, '0');
      expect(find.text('Enter an amount greater than zero.'), findsOneWidget);

      await _type(tester, '5000');
      expect(_enabled(tester, _send), isTrue);
    });
  });

  group('sending', () {
    testWidgets('one tap, one request; the key is a real key', (tester) async {
      final h = _Harness(dashboard: _rich());
      h.payouts.createGate = Completer<void>();
      await _open(tester, h);
      await _type(tester, '5000');
      await tester.tap(_send);
      await tester.pump();
      // The button is busy: a second tap finds nothing to press.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(FilledButton).last, warnIfMissed: false);
      await tester.pump();

      h.payouts.createGate!.complete();
      await tester.pumpAndSettle();
      expect(h.payouts.creates, hasLength(1));
      expect(h.payouts.creates.single.key, isNotEmpty);
    });

    testWidgets('success refreshes the dashboard, pops home, says who', (
      tester,
    ) async {
      final h = _Harness(dashboard: _rich());
      await _open(tester, h);
      final before = h.dashboard.calls;
      await _type(tester, '5000');
      await tester.tap(_send);
      await tester.pumpAndSettle();

      expect(h.dashboard.calls, before + 1);
      expect(routerOf(tester).state.matchedLocation, '/teen/home');
      expect(find.text('Request sent to Aigerim'), findsOneWidget);
    });
  });

  group('after a rejection', () {
    testWidgets('an edit makes a new key, an unrelated tap does not', (
      tester,
    ) async {
      final h = _Harness(dashboard: _rich());
      h.payouts.createError = const ApiException(
        code: 'amount_too_small',
        statusCode: 422,
      );
      await _open(tester, h);
      await _type(tester, '5000');
      await tester.tap(_send);
      await tester.pumpAndSettle();
      expect(
        find.text('That is below the smallest amount you can cash out.'),
        findsOneWidget,
      );
      final first = h.payouts.creates.single.key;

      // Same payload again, nothing edited: same key.
      await tester.tap(_send);
      await tester.pumpAndSettle();
      expect(h.payouts.creates.last.key, first);

      // Edit the amount: a new key, and the server error clears.
      h.payouts.createError = null;
      await _type(tester, '4000');
      await tester.pumpAndSettle(); // the error fades out
      expect(find.textContaining('smallest amount'), findsNothing);
      await tester.tap(_send);
      await tester.pumpAndSettle();
      expect(h.payouts.creates.last.key, isNot(first));
    });

    testWidgets('insufficient funds shows copy and the refreshed available', (
      tester,
    ) async {
      final h = _Harness(dashboard: _rich());
      h.payouts.createError = const ApiException(
        code: 'insufficient_funds',
        statusCode: 422,
      );
      await _open(tester, h);
      await _type(tester, '5000');
      // A penalty lands before the teen taps Send.
      h.dashboard.dashboard = fakeDashboard(
        balance: const Money.kzt(300000),
        locked: Money.zero,
        available: const Money.kzt(300000),
      );
      await tester.tap(_send);
      await tester.pumpAndSettle();

      expect(
        find.textContaining("You don't have that much available any more"),
        findsOneWidget,
      );
      expect(find.text('Available: ${_money(300000)}'), findsOneWidget);
    });

    testWidgets('already open: message, then only "Back to home"', (
      tester,
    ) async {
      final h = _Harness(dashboard: _rich());
      h.payouts.createError = const ApiException(
        code: 'payout_already_open',
        statusCode: 409,
      );
      await _open(tester, h);
      await _type(tester, '5000');
      final before = h.dashboard.calls;
      await tester.tap(_send);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('You already have a cash-out request open'),
        findsOneWidget,
      );
      expect(h.dashboard.calls, before + 1, reason: 'silent refresh');
      expect(_send, findsNothing);
      await tester.tap(find.text('Back to home'));
      await tester.pumpAndSettle();
      expect(routerOf(tester).state.matchedLocation, '/teen/home');
    });

    testWidgets('not linked any more', (tester) async {
      final h = _Harness(dashboard: _rich());
      h.payouts.createError = const ApiException(
        code: 'forbidden',
        statusCode: 403,
      );
      await _open(tester, h);
      await _type(tester, '5000');
      final calls = h.family.calls;
      await tester.tap(_send);
      await tester.pumpAndSettle();
      expect(
        find.text('You are no longer linked to this parent.'),
        findsOneWidget,
      );
      expect(h.family.calls, greaterThan(calls));
    });

    testWidgets('parent_required asks to choose', (tester) async {
      final h = _Harness(dashboard: _rich());
      h.payouts.createError = const ApiException(
        code: 'parent_required',
        statusCode: 422,
      );
      await _open(tester, h);
      await _type(tester, '5000');
      await tester.tap(_send);
      await tester.pumpAndSettle();
      expect(find.text('Choose who to ask.'), findsOneWidget);
    });
  });

  group('after an ambiguous failure', () {
    testWidgets(
      'locks, retries with the same key, edit details gets a new one',
      (tester) async {
        final h = _Harness(dashboard: _rich());
        h.payouts.createError = const ApiException(code: 'timeout');
        await _open(tester, h);
        await _type(tester, '5000');
        await tester.tap(_send);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('could not tell if the request was sent'),
          findsOneWidget,
        );
        expect(
          tester.widget<TextField>(find.byType(TextField)).enabled,
          isFalse,
        );
        expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);
        final key = h.payouts.creates.single.key;

        await tester.tap(find.widgetWithText(FilledButton, 'Try again'));
        await tester.pumpAndSettle();
        expect(h.payouts.creates.last.key, key);
        expect(h.payouts.creates.last.amount, const Money.kzt(500000));

        await tester.tap(find.text('Edit details'));
        await tester.pumpAndSettle();
        expect(find.text('Change the details?'), findsOneWidget);
        await tester.tap(find.text('Change anyway'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byType(TextField)).enabled,
          isTrue,
        );

        h.payouts.createError = null;
        await _type(tester, '4000');
        await tester.tap(_send);
        await tester.pumpAndSettle();
        expect(h.payouts.creates.last.key, isNot(key));
        expect(h.payouts.creates.last.amount, const Money.kzt(400000));
      },
    );
  });

  testWidgets('if a penalty makes the balance negative, the form explains', (
    tester,
  ) async {
    final h = _Harness(dashboard: _rich());
    await _open(tester, h);
    h.dashboard.dashboard = fakeDashboard(
      balance: const Money.kzt(-100),
      locked: Money.zero,
      available: const Money.kzt(-100),
    );
    // What a PENALTY_APPLIED push does.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TiynApp)),
    );
    await container.read(dashboardControllerProvider.notifier).refresh();
    await tester.pumpAndSettle();

    expect(find.textContaining('missed task'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();
    expect(routerOf(tester).state.matchedLocation, '/teen/home');
  });
}
