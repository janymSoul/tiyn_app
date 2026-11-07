import 'package:tiyn_app/core/money/money.dart';

/// The amount as the parent pastes it into a bank app: digits only, no
/// grouping and no currency. A comma for tiyn (`5000,50`); whether a bank's
/// field takes it is checked per bank on a phone.
String payoutCopyText(Money amount) {
  final whole = amount.minor ~/ 100;
  final fraction = amount.minor % 100;
  return fraction == 0
      ? '$whole'
      : '$whole,${fraction.toString().padLeft(2, '0')}';
}
