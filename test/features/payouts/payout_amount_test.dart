import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/features/payouts/application/payout_amount.dart';

const _available = Money.kzt(1000000); // 10 000 ₸

PayoutAmountError? _error(String input) =>
    validatePayoutAmount(input, available: _available).error;

void main() {
  test('not a number', () {
    for (final input in ['', 'abc', '1.2.3', '-5', '1 000 a']) {
      expect(_error(input), PayoutAmountError.invalid, reason: input);
    }
  });

  test('zero is "not positive", checked before the minimum', () {
    expect(_error('0'), PayoutAmountError.notPositive);
    expect(_error('0,00'), PayoutAmountError.notPositive);
  });

  test('below the minimum of 100 ₸', () {
    expect(_error('99'), PayoutAmountError.belowMinimum);
    expect(_error('99,99'), PayoutAmountError.belowMinimum);
  });

  test('exactly the minimum and exactly the available are fine', () {
    expect(
      validatePayoutAmount('100', available: _available).amount,
      const Money.kzt(10000),
    );
    expect(
      validatePayoutAmount('10 000', available: _available).amount,
      const Money.kzt(1000000),
    );
  });

  test('above available', () {
    expect(_error('10 000,01'), PayoutAmountError.aboveAvailable);
    expect(_error('999999999999'), PayoutAmountError.aboveAvailable);
  });

  test(
    'available below the minimum: any valid amount fails on the minimum',
    () {
      final result = validatePayoutAmount(
        '50',
        available: const Money.kzt(100),
      );
      expect(result.error, PayoutAmountError.belowMinimum);
    },
  );

  test('comma and dot both work for tiyn', () {
    expect(
      validatePayoutAmount('150,50', available: _available).amount,
      const Money.kzt(15050),
    );
    expect(
      validatePayoutAmount('150.5', available: _available).amount,
      const Money.kzt(15050),
    );
  });
}
