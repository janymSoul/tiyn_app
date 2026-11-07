import 'package:tiyn_app/app/config.dart';
import 'package:tiyn_app/core/money/money.dart';

enum PayoutAmountError { invalid, notPositive, belowMinimum, aboveAvailable }

class PayoutAmountResult {
  const PayoutAmountResult.ok(Money this.amount) : error = null;
  const PayoutAmountResult.error(PayoutAmountError this.error) : amount = null;

  final Money? amount;
  final PayoutAmountError? error;

  bool get isValid => amount != null;
}

/// Client-side check of what the teen typed. Advisory: the server's 422 is the
/// truth, and the minimum is a constant until the API exposes it.
PayoutAmountResult validatePayoutAmount(
  String input, {
  required Money available,
  Money minimum = kMinPayout,
}) {
  final amount = Money.parseTenge(input);
  if (amount == null) {
    return const PayoutAmountResult.error(PayoutAmountError.invalid);
  }
  if (amount.minor <= 0) {
    return const PayoutAmountResult.error(PayoutAmountError.notPositive);
  }
  if (amount.compareTo(minimum) < 0) {
    return const PayoutAmountResult.error(PayoutAmountError.belowMinimum);
  }
  if (amount.compareTo(available) > 0) {
    return const PayoutAmountResult.error(PayoutAmountError.aboveAvailable);
  }
  return PayoutAmountResult.ok(amount);
}
