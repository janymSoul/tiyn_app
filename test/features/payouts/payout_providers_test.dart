import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/features/payouts/application/payout_providers.dart';
import 'package:tiyn_app/features/payouts/data/payout.dart';
import 'package:tiyn_app/features/payouts/data/payout_state.dart';

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
}
