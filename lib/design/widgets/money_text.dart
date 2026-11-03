import 'package:flutter/material.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/money/money_format.dart';

class MoneyText extends StatelessWidget {
  const MoneyText(this.money, {super.key, this.style, this.signed = false});

  final Money money;
  final TextStyle? style;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return Text(
      formatMoney(money, locale: locale, signed: signed),
      style: style,
    );
  }
}
