import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/app/config.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/features/payouts/application/cash_out_rule.dart';
import 'package:tiyn_app/features/teen/data/dashboard.dart';

Balance _balance({int balance = 0, int locked = 0, int? available}) => Balance(
  balance: Money.kzt(balance),
  locked: Money.kzt(locked),
  available: Money.kzt(available ?? balance - locked),
);

void main() {
  test('the default minimum is 100 KZT', () {
    expect(kMinPayout, const Money.kzt(10000));
  });

  group('cashOutState', () {
    test('an open request wins over everything', () {
      final s = cashOutState(_balance(balance: -500), hasOpenRequest: true);
      expect(s, isA<CashOutOpenRequest>());
    });

    test('a negative balance is a debt, with the positive amount owed', () {
      final s = cashOutState(_balance(balance: -250000), hasOpenRequest: false);
      expect(s, isA<CashOutInDebt>());
      expect((s as CashOutInDebt).owed, const Money.kzt(250000));
    });

    test('debt is checked before the minimum, even with money locked', () {
      final s = cashOutState(
        _balance(balance: -100, locked: 500000),
        hasOpenRequest: false,
      );
      expect(s, isA<CashOutInDebt>());
    });

    test('below the minimum without locked money', () {
      final s = cashOutState(_balance(balance: 9999), hasOpenRequest: false);
      expect(s, isA<CashOutBelowMinimum>());
      s as CashOutBelowMinimum;
      expect(s.minimum, kMinPayout);
      expect(s.hasLocked, isFalse);
    });

    test('below the minimum because of locked money says so', () {
      final s = cashOutState(
        _balance(balance: 500000, locked: 495000),
        hasOpenRequest: false,
      );
      expect((s as CashOutBelowMinimum).hasLocked, isTrue);
    });

    test('locked above a non-negative balance is below minimum, not debt', () {
      final s = cashOutState(
        _balance(balance: 100, locked: 500000),
        hasOpenRequest: false,
      );
      expect(s, isA<CashOutBelowMinimum>());
    });

    test('exactly the minimum is allowed', () {
      final s = cashOutState(_balance(balance: 10000), hasOpenRequest: false);
      expect(s, isA<CashOutAllowed>());
    });

    test('zero balance is below the minimum, not debt', () {
      final s = cashOutState(_balance(), hasOpenRequest: false);
      expect(s, isA<CashOutBelowMinimum>());
    });
  });
}
