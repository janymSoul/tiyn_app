import 'package:intl/intl.dart';
import 'package:tiyn_app/core/money/money.dart';

const _nbsp = ' ';

String formatMoney(Money money, {required String locale, bool signed = false}) {
  assert(money.currency == 'KZT', 'Only KZT is supported');
  final format = NumberFormat.decimalPattern(locale);
  final symbols = format.symbols;
  final abs = money.minor.abs();
  final whole = format.format(abs ~/ 100).replaceAll(symbols.GROUP_SEP, _nbsp);
  final fraction = abs % 100;
  final body = fraction == 0
      ? whole
      : '$whole${symbols.DECIMAL_SEP}${fraction.toString().padLeft(2, '0')}';
  final sign = money.isNegative ? '−' : (signed && !money.isZero ? '+' : '');
  return '$sign$body$_nbsp₸';
}
