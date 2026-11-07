import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/bank/bank.dart';
import 'package:tiyn_app/core/bank/bank_launcher.dart';
import 'package:tiyn_app/core/bank/bank_providers.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/money/money_format.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/features/payouts/application/payout_copy_text.dart';
import 'package:tiyn_app/features/payouts/data/cancel_reason.dart';
import 'package:tiyn_app/features/payouts/data/payout_state.dart';

import '../../helpers/fake_bank_launcher.dart';
import '../../helpers/fake_payouts.dart';
import '../../helpers/parent_harness.dart';
import '../../helpers/pump_app.dart';

String _money(int minor) => formatMoney(Money.kzt(minor), locale: 'en');

ParentHarness _harness() {
  final h = ParentHarness(teens: [(id: 'teen1', name: 'Dana')]);
  h.payouts.payouts = [
    fakePayout(
      amount: const Money.kzt(500000),
      requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
      expiresAt: DateTime.now().add(const Duration(days: 6, hours: 22)),
    ),
  ];
  return h;
}

Future<void> _openPayout(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('To check'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Cash-out request'));
  await tester.pumpAndSettle();
}

Finder get _sent => find.widgetWithText(FilledButton, 'I sent it');
Finder get _decline => find.widgetWithText(OutlinedButton, 'Decline');

void main() {
  group('the screen', () {
    testWidgets('a row opens it; it shows who, how much, and the two steps', (
      tester,
    ) async {
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      await _openPayout(tester);

      expect(find.text('Dana asks for'), findsOneWidget);
      expect(find.text(_money(500000)), findsWidgets);
      expect(find.text('6 days left'), findsOneWidget);
      expect(find.text('1. Send the money'), findsOneWidget);
      expect(find.text('2. Then confirm'), findsOneWidget);
      expect(find.text('Copy amount'), findsOneWidget);
      expect(_sent, findsOneWidget);
      expect(_decline, findsOneWidget);
      expect(h.payouts.fulfils, isEmpty, reason: 'opening it fulfils nothing');
    });

    testWidgets('back returns to the To check list', (tester) async {
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      await _openPayout(tester);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Payout requests (1)'), findsOneWidget);
    });

    testWidgets('Copy puts digits only on the clipboard', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      await _openPayout(tester);
      await tester.tap(find.text('Copy amount'));
      await tester.pumpAndSettle();
      expect(copied, '5000');
      expect(find.text('Amount copied'), findsOneWidget);
    });

    test('the copied text: whole tenge plain, tiyn after a comma', () {
      expect(payoutCopyText(const Money.kzt(500000)), '5000');
      expect(payoutCopyText(const Money.kzt(500050)), '5000,50');
      expect(payoutCopyText(const Money.kzt(500005)), '5000,05');
      expect(payoutCopyText(const Money.kzt(10000)), '100');
    });

    testWidgets('a resume refetches the payout', (tester) async {
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      await _openPayout(tester);
      final calls = h.payouts.gets.length;

      final binding = tester.binding;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(h.payouts.gets.length, greaterThan(calls));
    });
  });

  group('I sent it', () {
    testWidgets('asks first, names the amount, and sends nothing until yes', (
      tester,
    ) async {
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      await _openPayout(tester);

      await tester.tap(_sent);
      await tester.pumpAndSettle();
      expect(find.text('Confirm you sent ${_money(500000)}?'), findsOneWidget);
      expect(
        find.textContaining('Tiyn can\'t see the transfer'),
        findsOneWidget,
      );
      expect(h.payouts.fulfils, isEmpty);

      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();
      expect(h.payouts.fulfils, isEmpty);
      expect(_sent, findsOneWidget);
    });

    testWidgets('yes fulfils once, goes back to the list and refreshes it', (
      tester,
    ) async {
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      await _openPayout(tester);
      h.payouts.fulfilGate = Completer<void>();

      await tester.tap(_sent);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, I sent it'));
      await tester.pump();
      await tester.pump();
      // Busy: both actions are inert, so a second tap cannot double-send.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(_decline, warnIfMissed: false);
      await tester.pump();

      h.payouts.payouts = [];
      h.payouts.fulfilGate!.complete();
      await tester.pumpAndSettle();

      expect(h.payouts.fulfils, ['po1']);
      expect(h.payouts.declines, isEmpty);
      expect(find.text('Payout confirmed'), findsOneWidget);
      expect(find.text('Payout requests (1)'), findsNothing);
      expect(find.text('Nothing to check. Nice!'), findsOneWidget);
    });

    testWidgets(
      'insufficient funds: why, no "I sent it", Decline still works',
      (tester) async {
        final h = _harness();
        h.payouts.fulfilError = const ApiException(
          code: 'insufficient_funds',
          statusCode: 422,
        );
        await pumpApp(tester, overrides: h.overrides);
        await _openPayout(tester);

        await tester.tap(_sent);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yes, I sent it'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('no longer covers ${_money(500000)}'),
          findsOneWidget,
        );
        expect(_sent, findsNothing);
        expect(find.text('Copy amount'), findsNothing);
        expect(_decline, findsOneWidget);
        expect(h.payouts.fulfils, hasLength(1));

        await tester.tap(_decline);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yes, decline'));
        await tester.pumpAndSettle();
        expect(h.payouts.declines, ['po1']);
        expect(find.text('Request declined'), findsOneWidget);
      },
    );

    testWidgets('409: reloads and shows how it really ended', (tester) async {
      final h = _harness();
      h.payouts.fulfilError = const ApiException(
        code: 'invalid_transition',
        statusCode: 409,
      );
      await pumpApp(tester, overrides: h.overrides);
      await _openPayout(tester);

      // The teen cancelled while the parent was in the bank app.
      h.payouts.payouts = [
        fakePayout(
          state: PayoutState.cancelled,
          cancelReason: CancelReason.teenCancelled,
        ),
      ];
      await tester.tap(_sent);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, I sent it'));
      await tester.pumpAndSettle();

      expect(find.text('The teen cancelled this request'), findsOneWidget);
      expect(
        find.text('This request just changed. Here is the latest.'),
        findsOneWidget,
      );
      expect(_sent, findsNothing);
      expect(_decline, findsNothing);
    });

    testWidgets('409 on a payout that is already fulfilled says so', (
      tester,
    ) async {
      final h = _harness();
      h.payouts.fulfilError = const ApiException(
        code: 'invalid_transition',
        statusCode: 409,
      );
      await pumpApp(tester, overrides: h.overrides);
      await _openPayout(tester);
      h.payouts.payouts = [fakePayout(state: PayoutState.fulfilled)];
      await tester.tap(_sent);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, I sent it'));
      await tester.pumpAndSettle();
      expect(find.text('Payout confirmed'), findsOneWidget);
    });

    testWidgets('403: no longer linked', (tester) async {
      final h = _harness();
      h.payouts.fulfilError = const ApiException(
        code: 'forbidden',
        statusCode: 403,
      );
      await pumpApp(tester, overrides: h.overrides);
      await _openPayout(tester);
      await tester.tap(_sent);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, I sent it'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'You are no longer linked to this teen. The request was cancelled.',
        ),
        findsOneWidget,
      );
      expect(_sent, findsNothing);
    });

    testWidgets(
      'a timeout reloads first, then offers Try again without asking',
      (tester) async {
        final h = _harness();
        h.payouts.fulfilError = const ApiException(code: 'timeout');
        await pumpApp(tester, overrides: h.overrides);
        await _openPayout(tester);
        final gets = h.payouts.gets.length;

        await tester.tap(_sent);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yes, I sent it'));
        await tester.pumpAndSettle();

        expect(
          h.payouts.gets.length,
          greaterThan(gets),
          reason: 'looked first',
        );
        expect(
          find.text('The server took too long to answer. Try again.'),
          findsOneWidget,
        );
        expect(_sent, findsNothing);

        h.payouts.fulfilError = null;
        await tester.tap(find.widgetWithText(FilledButton, 'Try again'));
        await tester.pumpAndSettle();
        expect(
          find.text('Confirm you sent ${_money(500000)}?'),
          findsNothing,
          reason: 'already confirmed',
        );
        expect(h.payouts.fulfils, hasLength(2));
        expect(find.text('Payout confirmed'), findsOneWidget);
      },
    );

    testWidgets('a timeout that actually landed shows it as done', (
      tester,
    ) async {
      final h = _harness();
      h.payouts.fulfilError = const ApiException(code: 'network_error');
      await pumpApp(tester, overrides: h.overrides);
      await _openPayout(tester);
      h.payouts.payouts = [fakePayout(state: PayoutState.fulfilled)];

      await tester.tap(_sent);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, I sent it'));
      await tester.pumpAndSettle();

      expect(find.text('Payout confirmed'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Try again'), findsNothing);
    });
  });

  group('Decline', () {
    testWidgets('asks first; keeping it open does nothing', (tester) async {
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      await _openPayout(tester);
      await tester.tap(_decline);
      await tester.pumpAndSettle();
      expect(
        find.text('Decline the ${_money(500000)} request?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Keep it open'));
      await tester.pumpAndSettle();
      expect(h.payouts.declines, isEmpty);
      expect(_decline, findsOneWidget);
    });

    testWidgets('yes declines once and goes back to the list', (tester) async {
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      await _openPayout(tester);
      h.payouts.payouts = [];
      await tester.tap(_decline);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, decline'));
      await tester.pumpAndSettle();
      expect(h.payouts.declines, ['po1']);
      expect(h.payouts.fulfils, isEmpty);
      expect(find.text('Request declined'), findsOneWidget);
      expect(find.text('Nothing to check. Nice!'), findsOneWidget);
    });

    testWidgets('409 shows how it ended', (tester) async {
      final h = _harness();
      h.payouts.declineError = const ApiException(
        code: 'invalid_transition',
        statusCode: 409,
      );
      await pumpApp(tester, overrides: h.overrides);
      await _openPayout(tester);
      h.payouts.payouts = [
        fakePayout(
          state: PayoutState.cancelled,
          cancelReason: CancelReason.expired,
        ),
      ];
      await tester.tap(_decline);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, decline'));
      await tester.pumpAndSettle();
      expect(find.text('This request expired'), findsOneWidget);
    });
  });

  group('a payout that is not open', () {
    for (final (state, reason, title) in [
      (PayoutState.fulfilled, null, 'Payout confirmed'),
      (
        PayoutState.cancelled,
        CancelReason.teenCancelled,
        'The teen cancelled this request',
      ),
      (
        PayoutState.cancelled,
        CancelReason.declined,
        'You declined this request',
      ),
      (PayoutState.cancelled, CancelReason.expired, 'This request expired'),
      (
        PayoutState.cancelled,
        CancelReason.unlinked,
        'You are no longer linked to this teen. The request was cancelled.',
      ),
    ]) {
      testWidgets('${state.wire} ${reason?.wire ?? ''} shows no actions', (
        tester,
      ) async {
        final h = _harness();
        await pumpApp(tester, overrides: h.overrides);
        await _openPayout(tester);
        h.payouts.payouts = [fakePayout(state: state, cancelReason: reason)];
        final binding = tester.binding;
        binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();

        expect(find.text(title), findsOneWidget);
        expect(_sent, findsNothing);
        expect(_decline, findsNothing);
        expect(find.text('Copy amount'), findsNothing);
      });
    }
  });

  group('loading', () {
    testWidgets('404 says it is not available', (tester) async {
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      await _openPayout(tester);
      h.payouts.payouts = [];
      // Open an id the server does not know.
      routerOf(tester).go('/parent/review/payout/nope');
      await tester.pumpAndSettle();
      expect(find.text('This request is no longer available.'), findsOneWidget);
    });

    testWidgets('a network failure offers Try again', (tester) async {
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      h.payouts.getError = const ApiException(code: 'network_error');
      routerOf(tester).go('/parent/review/payout/po1');
      await tester.pumpAndSettle();
      expect(find.text('No connection. Check your network.'), findsOneWidget);

      h.payouts.getError = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(_sent, findsOneWidget);
    });
  });

  group('opening a bank app', () {
    const kaspi = Bank(
      id: 'kaspi',
      displayName: 'Kaspi',
      androidPackage: 'kz.example.kaspi',
    );

    Future<FakeBankLauncher> open(
      WidgetTester tester,
      ParentHarness h, {
      BankLaunchResult result = BankLaunchResult.opened,
      List<Bank>? banks,
    }) async {
      final launcher = FakeBankLauncher(result);
      await pumpApp(
        tester,
        overrides: [
          ...h.overrides,
          bankLauncherProvider.overrideWithValue(launcher),
          if (banks != null) banksProvider.overrideWithValue(banks),
        ],
      );
      await _openPayout(tester);
      return launcher;
    }

    testWidgets('one bank: a single button that opens it', (tester) async {
      final h = _harness();
      final launcher = await open(tester, h);
      expect(find.text('Open Freedom Bank'), findsOneWidget);

      await tester.tap(find.text('Open Freedom Bank'));
      await tester.pumpAndSettle();
      expect(launcher.opened.single.id, 'freedom');
    });

    testWidgets('opening a bank never fulfils, before or after a resume', (
      tester,
    ) async {
      final h = _harness();
      final launcher = await open(tester, h);
      await tester.tap(find.text('Open Freedom Bank'));
      await tester.pumpAndSettle();

      final binding = tester.binding;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(launcher.opened, hasLength(1));
      expect(h.payouts.fulfils, isEmpty);
      expect(h.payouts.declines, isEmpty);
      expect(_sent, findsOneWidget, reason: 'still waiting for the parent');
    });

    for (final (result, note) in [
      (BankLaunchResult.opened, null),
      (
        BankLaunchResult.storeOpened,
        "Freedom Bank isn't installed. We opened its store page.",
      ),
      (
        BankLaunchResult.unavailable,
        'Could not open Freedom Bank. Open it yourself, then come back and '
            'confirm.',
      ),
    ]) {
      testWidgets('${result.name}: amount and copy stay, confirm still works', (
        tester,
      ) async {
        final h = _harness();
        await open(tester, h, result: result);
        await tester.tap(find.text('Open Freedom Bank'));
        await tester.pumpAndSettle();

        if (note != null) expect(find.text(note), findsOneWidget);
        expect(find.text('Copy amount'), findsOneWidget);
        expect(find.text(_money(500000)), findsWidgets);
        expect(h.payouts.fulfils, isEmpty);

        await tester.tap(_sent);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yes, I sent it'));
        await tester.pumpAndSettle();
        expect(h.payouts.fulfils, ['po1']);
      });
    }

    testWidgets('several banks: a list, each opening its own app', (
      tester,
    ) async {
      final h = _harness();
      final launcher = await open(tester, h, banks: [freedomBank, kaspi]);
      expect(find.text('Open Freedom Bank'), findsOneWidget);
      expect(find.text('Open Kaspi'), findsOneWidget);

      await tester.tap(find.text('Open Kaspi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Freedom Bank'));
      await tester.pumpAndSettle();
      expect(launcher.opened.map((b) => b.id), ['kaspi', 'freedom']);
    });

    testWidgets('no bank button once the request is not open', (tester) async {
      final h = _harness();
      await open(tester, h);
      h.payouts.payouts = [fakePayout(state: PayoutState.fulfilled)];
      final binding = tester.binding;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Open Freedom Bank'), findsNothing);
    });
  });

  group('leaving while the call is in flight', () {
    testWidgets('Back during fulfil: it still lands, the list is refreshed', (
      tester,
    ) async {
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      await _openPayout(tester);
      h.payouts.fulfilGate = Completer<void>();

      await tester.tap(_sent);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, I sent it'));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      final lists = h.payouts.listStates.length;

      h.payouts.payouts = [];
      h.payouts.fulfilGate!.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(h.payouts.fulfils, ['po1'], reason: 'sent once');
      expect(h.payouts.listStates.length, greaterThan(lists));
      expect(find.text('Payout requests (1)'), findsNothing);
      expect(find.text('Payout confirmed'), findsOneWidget);
    });

    testWidgets('an unsure fulfil also refreshes the list', (tester) async {
      final h = _harness();
      h.payouts.fulfilError = const ApiException(code: 'timeout');
      await pumpApp(tester, overrides: h.overrides);
      await _openPayout(tester);
      final lists = h.payouts.listStates.length;

      await tester.tap(_sent);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, I sent it'));
      await tester.pumpAndSettle();

      expect(h.payouts.listStates.length, greaterThan(lists));
    });
  });
}
