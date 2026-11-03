import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/money/money_format.dart';
import 'package:tiyn_app/core/network/api_exception.dart';

const _n = ' ';

void main() {
  group('formatMoney', () {
    final cases = <({int minor, String locale, bool signed, String expected})>[
      (minor: 0, locale: 'ru', signed: false, expected: '0$_n₸'),
      (minor: 100, locale: 'ru', signed: false, expected: '1$_n₸'),
      (minor: 150000, locale: 'ru', signed: false, expected: '1${_n}500$_n₸'),
      (minor: 1000000, locale: 'ru', signed: false, expected: '10${_n}000$_n₸'),
      (
        minor: 150050,
        locale: 'ru',
        signed: false,
        expected: '1${_n}500,50$_n₸',
      ),
      (minor: 5, locale: 'ru', signed: false, expected: '0,05$_n₸'),
      (minor: -30000, locale: 'ru', signed: false, expected: '−300$_n₸'),
      (minor: 150000, locale: 'ru', signed: true, expected: '+1${_n}500$_n₸'),
      (minor: -30000, locale: 'ru', signed: true, expected: '−300$_n₸'),
      (minor: 0, locale: 'ru', signed: true, expected: '0$_n₸'),
      (minor: 150000, locale: 'kk', signed: false, expected: '1${_n}500$_n₸'),
      (
        minor: 150050,
        locale: 'kk',
        signed: false,
        expected: '1${_n}500,50$_n₸',
      ),
      (
        minor: 123456700,
        locale: 'kk',
        signed: false,
        expected: '1${_n}234${_n}567$_n₸',
      ),
      (minor: 150000, locale: 'en', signed: false, expected: '1${_n}500$_n₸'),
      (
        minor: 150050,
        locale: 'en',
        signed: false,
        expected: '1${_n}500.50$_n₸',
      ),
      (minor: 150000, locale: 'en', signed: true, expected: '+1${_n}500$_n₸'),
    ];
    for (final c in cases) {
      test('${c.minor} ${c.locale} signed=${c.signed}', () {
        expect(
          formatMoney(Money.kzt(c.minor), locale: c.locale, signed: c.signed),
          c.expected,
        );
      });
    }
  });

  group('parseTenge', () {
    final valid = <String, int>{
      '10 000': 1000000,
      '10000': 1000000,
      '1 500,50': 150050,
      '1500.5': 150050,
      '0,05': 5,
      '  7 ': 700,
      '10${_n}000': 1000000,
      '92233720368547758,07': 9223372036854775807,
    };
    valid.forEach((input, minor) {
      test('"$input" -> $minor', () {
        expect(Money.parseTenge(input), Money.kzt(minor));
      });
    });

    for (final input in [
      '',
      '   ',
      'abc',
      '12a',
      '-5',
      '1,234',
      '1.234,5',
      '1,',
      ',5',
      '92233720368547758,08',
      '92233720368547759',
      '99999999999999999999',
    ]) {
      test(
        '"$input" is invalid',
        () => expect(Money.parseTenge(input), isNull),
      );
    }
  });

  group('Money', () {
    test('arithmetic and ordering', () {
      expect(const Money.kzt(100) + const Money.kzt(50), const Money.kzt(150));
      expect(const Money.kzt(100) - const Money.kzt(150), const Money.kzt(-50));
      expect(const Money.kzt(1).compareTo(const Money.kzt(2)), lessThan(0));
      expect(const Money.kzt(-1).isNegative, isTrue);
      expect(Money.zero.isZero, isTrue);
    });

    test('currency mismatch throws', () {
      expect(
        () => const Money.kzt(1) + const Money(1, 'USD'),
        throwsArgumentError,
      );
    });

    test('equality and hashCode', () {
      expect(const Money.kzt(5), const Money.kzt(5));
      expect(const Money.kzt(5).hashCode, const Money.kzt(5).hashCode);
      expect(const Money.kzt(5) == const Money(5, 'USD'), isFalse);
    });

    test('fromJson validates int and KZT', () {
      expect(Money.fromJson(150000, 'KZT'), const Money.kzt(150000));
      for (final bad in [
        (1.5, 'KZT'),
        ('100', 'KZT'),
        (null, 'KZT'),
        (100, 'USD'),
        (100, null),
      ]) {
        expect(
          () => Money.fromJson(bad.$1, bad.$2),
          throwsA(
            isA<ApiException>().having(
              (e) => e.code,
              'code',
              'invalid_response',
            ),
          ),
        );
      }
    });
  });
}
