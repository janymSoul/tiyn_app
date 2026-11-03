import 'package:flutter/foundation.dart';
import 'package:tiyn_app/core/network/api_exception.dart';

@immutable
final class Money implements Comparable<Money> {
  const Money(this.minor, this.currency);
  const Money.kzt(this.minor) : currency = 'KZT';

  factory Money.fromJson(Object? amount, Object? currency) {
    if (amount is! int || currency != 'KZT') {
      throw const ApiException(code: 'invalid_response');
    }
    return Money.kzt(amount);
  }

  static const zero = Money.kzt(0);

  final int minor;
  final String currency;

  static final _tenge = RegExp(r'^(\d+)(?:[.,](\d{1,2}))?$');
  static final _maxMinor = BigInt.from(0x7FFFFFFFFFFFFFFF);

  /// Parses user input such as "10 000", "10000" or "1 500,50" into minor units.
  static Money? parseTenge(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\s  ]'), '');
    final match = _tenge.firstMatch(cleaned);
    if (match == null) return null;
    final fraction = (match.group(2) ?? '').padRight(2, '0');
    final minor =
        BigInt.parse(match.group(1)!) * BigInt.from(100) +
        BigInt.parse(fraction);
    if (minor > _maxMinor) return null;
    return Money.kzt(minor.toInt());
  }

  Money operator +(Money other) {
    _requireSameCurrency(other);
    return Money(minor + other.minor, currency);
  }

  Money operator -(Money other) {
    _requireSameCurrency(other);
    return Money(minor - other.minor, currency);
  }

  bool get isNegative => minor < 0;
  bool get isZero => minor == 0;

  void _requireSameCurrency(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Currency mismatch: $currency vs ${other.currency}');
    }
  }

  @override
  int compareTo(Money other) {
    _requireSameCurrency(other);
    return minor.compareTo(other.minor);
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.minor == minor && other.currency == currency;

  @override
  int get hashCode => Object.hash(minor, currency);

  @override
  String toString() => 'Money($minor $currency)';
}
