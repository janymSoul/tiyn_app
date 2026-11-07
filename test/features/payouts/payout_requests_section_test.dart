import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/app/app.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/money/money_format.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/features/payouts/application/payout_providers.dart';
import 'package:tiyn_app/features/payouts/data/payout_state.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

import '../../helpers/fake_payouts.dart';
import '../../helpers/fake_tasks.dart';
import '../../helpers/parent_harness.dart';
import '../../helpers/pump_app.dart';

const _dana = (id: 'teen1', name: 'Dana');
const _aibek = (id: 'teen2', name: 'Aibek');

String _money(int minor) => formatMoney(Money.kzt(minor), locale: 'en');

DateTime _ago(int hours) => DateTime.now().subtract(Duration(hours: hours));

/// Two requests with the older one for Aibek, so the order is not the teen
/// order of the family list.
ParentHarness _harness({bool proofs = false}) {
  final h = ParentHarness(teens: [_dana, _aibek]);
  h.payouts.payouts = [
    fakePayout(
      id: 'new',
      teenId: 'teen1',
      amount: const Money.kzt(300000),
      requestedAt: _ago(1),
      expiresAt: DateTime.now().add(const Duration(days: 6, hours: 23)),
    ),
    fakePayout(
      id: 'old',
      teenId: 'teen2',
      amount: const Money.kzt(700000),
      requestedAt: _ago(30),
      expiresAt: DateTime.now().add(const Duration(days: 5, hours: 18)),
    ),
  ];
  if (proofs) {
    h.tasks.tasks = [
      fakeTask(
        id: 't1',
        teenId: 'teen1',
        title: 'Wash dishes',
        state: TaskState.submitted,
        submittedAt: DateTime.utc(2026, 11, 7, 8),
      ),
    ];
  }
  return h;
}

Future<void> _openToCheck(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('To check'),
    ),
  );
  await tester.pumpAndSettle();
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(TiynApp)));

void main() {
  group('the section', () {
    testWidgets('sits above the proofs, oldest request first', (tester) async {
      final h = _harness(proofs: true);
      await pumpApp(tester, overrides: h.overrides);
      await _openToCheck(tester);

      expect(find.text('Payout requests (2)'), findsOneWidget);
      expect(find.text('Proofs (1)'), findsOneWidget);

      double top(Finder f) => tester.getTopLeft(f).dy;
      final older = find.text(_money(700000));
      final newer = find.text(_money(300000));
      expect(top(older), lessThan(top(newer)), reason: 'oldest first');
      expect(top(newer), lessThan(top(find.text('Proofs (1)'))));
      expect(
        top(find.text('Proofs (1)')),
        lessThan(top(find.text('Wash dishes'))),
      );
    });

    testWidgets('names the teen and shows the time left', (tester) async {
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      await _openToCheck(tester);

      expect(find.text('Aibek'), findsOneWidget);
      expect(find.text('Dana'), findsOneWidget);
      expect(find.text('5 days left'), findsOneWidget);
      expect(find.text('6 days left'), findsOneWidget);
      expect(find.text('Cash-out request'), findsNWidgets(2));
    });

    testWidgets('requests only: no proofs header, no empty sentence', (
      tester,
    ) async {
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      await _openToCheck(tester);
      expect(find.textContaining('Proofs ('), findsNothing);
      expect(find.text('Nothing to check. Nice!'), findsNothing);
    });

    testWidgets('proofs only: looks as before payouts, no section', (
      tester,
    ) async {
      final h = _harness(proofs: true)..payouts.payouts = [];
      await pumpApp(tester, overrides: h.overrides);
      await _openToCheck(tester);
      expect(find.textContaining('Payout requests'), findsNothing);
      expect(find.textContaining('Proofs ('), findsNothing);
      expect(find.text('Wash dishes'), findsOneWidget);
    });

    testWidgets('the whole-tab empty sentence shows only when both are empty', (
      tester,
    ) async {
      final h = _harness()..payouts.payouts = [];
      await pumpApp(tester, overrides: h.overrides);
      await _openToCheck(tester);
      expect(find.text('Nothing to check. Nice!'), findsOneWidget);
    });
  });

  group('the two lists are independent', () {
    testWidgets('a failing payout list keeps the proofs, with its own retry', (
      tester,
    ) async {
      final h = _harness(proofs: true)
        ..payouts.listError = const ApiException(code: 'network_error');
      await pumpApp(tester, overrides: h.overrides);
      await _openToCheck(tester);

      expect(find.text('Wash dishes'), findsOneWidget);
      expect(find.text('No connection. Check your network.'), findsOneWidget);

      h.payouts.listError = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Payout requests (2)'), findsOneWidget);
      expect(find.text('Wash dishes'), findsOneWidget);
    });

    testWidgets('a failing proofs list keeps the requests', (tester) async {
      final h = _harness()
        ..tasks.error = const ApiException(code: 'network_error');
      await pumpApp(tester, overrides: h.overrides);
      await _openToCheck(tester);
      expect(find.text('Payout requests (2)'), findsOneWidget);
      expect(find.text(_money(700000)), findsOneWidget);
    });
  });

  group('the badge', () {
    testWidgets('counts proofs and payout requests together', (tester) async {
      final h = _harness(proofs: true);
      await pumpApp(tester, overrides: h.overrides);
      expect(
        find.descendant(of: find.byType(Badge), matching: find.text('3')),
        findsOneWidget,
      );
    });

    testWidgets('requests alone raise it; hidden at 0; 9+ above nine', (
      tester,
    ) async {
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      expect(
        find.descendant(of: find.byType(Badge), matching: find.text('2')),
        findsOneWidget,
      );

      h.payouts.payouts = [];
      await _container(tester)
          .read(requestedPayoutsProvider.notifier)
          .refresh();
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsNothing);

      h.payouts.payouts = [
        for (var i = 0; i < 10; i++) fakePayout(id: 'p$i', teenId: 'teen1'),
      ];
      await _container(tester)
          .read(requestedPayoutsProvider.notifier)
          .refresh();
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(Badge), matching: find.text('9+')),
        findsOneWidget,
      );
    });
  });

  group('refetching', () {
    testWidgets('one GET /payouts?state=REQUESTED at start, one more on '
        'selecting the tab, nothing else', (tester) async {
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      expect(h.payouts.listStates, [PayoutState.requested]);

      await _openToCheck(tester);
      expect(h.payouts.listStates, [
        PayoutState.requested,
        PayoutState.requested,
      ]);
    });

    testWidgets('selecting the tab again refetches silently', (tester) async {
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      await _openToCheck(tester);
      final calls = h.payouts.listStates.length;

      h.payouts.payouts = h.payouts.payouts.take(1).toList();
      await _openToCheck(tester);
      expect(h.payouts.listStates.length, calls + 1);
      expect(find.text('Payout requests (1)'), findsOneWidget);
    });

    testWidgets('a failed refetch keeps the list on screen', (tester) async {
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      await _openToCheck(tester);

      h.payouts.listError = const ApiException(code: 'network_error');
      await _openToCheck(tester);
      expect(find.text('Payout requests (2)'), findsOneWidget);
      expect(find.text('No connection. Check your network.'), findsNothing);
    });

    testWidgets('a resume refetches the visible tab', (tester) async {
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      await _openToCheck(tester);
      final calls = h.payouts.listStates.length;

      final binding = tester.binding;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(h.payouts.listStates.length, greaterThan(calls));
    });

    testWidgets('the Home tab refresh keeps the badge current', (tester) async {
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      final calls = h.payouts.listStates.length;

      h.payouts.payouts = [];
      await tester.fling(
        find.byType(ListView).first,
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();
      expect(h.payouts.listStates.length, greaterThan(calls));
      expect(find.byType(Badge), findsNothing);
    });
  });
}
