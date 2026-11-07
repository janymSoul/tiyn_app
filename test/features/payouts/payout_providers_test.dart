import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/features/payouts/application/payout_providers.dart';
import 'package:tiyn_app/features/payouts/data/payout.dart';
import 'package:tiyn_app/features/payouts/data/payout_state.dart';

import '../../helpers/fake_payouts.dart';

Payout _p(String id, DateTime requestedAt) => Payout(
  id: id,
  teenId: 'teen',
  parentId: 'parent',
  amount: const Money.kzt(10000),
  state: PayoutState.requested,
  requestedAt: requestedAt,
  expiresAt: requestedAt.add(const Duration(days: 7)),
);

void main() {
  test('payoutQueue puts the oldest request first, ties by id', () {
    final t = DateTime.utc(2026, 11, 1);
    final queue = payoutQueue([
      _p('c', t.add(const Duration(hours: 2))),
      _p('b', t),
      _p('a', t),
    ]);
    expect(queue.map((p) => p.id), ['a', 'b', 'c']);
  });

  test('payoutQueue does not mutate its input', () {
    final t = DateTime.utc(2026, 11, 1);
    final input = [_p('b', t.add(const Duration(hours: 1))), _p('a', t)];
    payoutQueue(input);
    expect(input.map((p) => p.id), ['b', 'a']);
  });

  group('PayoutDetailController.refresh', () {
    Future<(ProviderContainer, FakePayoutRepository)> loaded() async {
      final repo = FakePayoutRepository([fakePayout()]);
      final container = ProviderContainer(
        overrides: [payoutRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.listen(payoutDetailProvider('po1'), (_, _) {});
      await container.read(payoutDetailProvider('po1').future);
      return (container, repo);
    }

    for (final error in [
      const ApiException(code: 'network_error'),
      const ApiException(code: 'timeout'),
      const ApiException(code: 'internal_error', statusCode: 503),
    ]) {
      test('a transient failure (${error.code}) keeps the payout', () async {
        final (container, repo) = await loaded();
        repo.getError = error;
        await container.read(payoutDetailProvider('po1').notifier).refresh();
        final state = container.read(payoutDetailProvider('po1'));
        expect(state.hasError, isFalse);
        expect(state.value?.id, 'po1');
      });
    }

    for (final error in [
      const ApiException(code: 'not_found', statusCode: 404),
      const ApiException(code: 'forbidden', statusCode: 403),
    ]) {
      test('${error.code} replaces the payout with the error', () async {
        final (container, repo) = await loaded();
        repo.getError = error;
        await container.read(payoutDetailProvider('po1').notifier).refresh();
        expect(container.read(payoutDetailProvider('po1')).hasError, isTrue);
      });
    }
  });
}
