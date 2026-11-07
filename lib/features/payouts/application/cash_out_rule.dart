import 'package:tiyn_app/app/config.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/features/teen/data/dashboard.dart';

/// Whether the teen can start a cash-out, and if not, why.
sealed class CashOutState {
  const CashOutState();
}

/// A request is already open: the card shows instead of the button.
class CashOutOpenRequest extends CashOutState {
  const CashOutOpenRequest();
}

/// The balance is negative (a penalty debt). [owed] is a positive amount.
class CashOutInDebt extends CashOutState {
  const CashOutInDebt(this.owed);

  final Money owed;
}

/// Not enough available. [hasLocked] says whether money is set aside for
/// goals, which the copy mentions.
class CashOutBelowMinimum extends CashOutState {
  const CashOutBelowMinimum({required this.minimum, required this.hasLocked});

  final Money minimum;
  final bool hasLocked;
}

class CashOutAllowed extends CashOutState {
  const CashOutAllowed();
}

/// Checked in this order. Balance comes before available because `locked` can
/// exceed a balance a penalty reduced, and the debt copy would then be wrong.
CashOutState cashOutState(
  Balance balance, {
  required bool hasOpenRequest,
  Money minimum = kMinPayout,
}) {
  if (hasOpenRequest) return const CashOutOpenRequest();
  if (balance.balance.isNegative) {
    return CashOutInDebt(
      Money(-balance.balance.minor, balance.balance.currency),
    );
  }
  if (balance.available.compareTo(minimum) < 0) {
    return CashOutBelowMinimum(
      minimum: minimum,
      hasLocked: balance.locked.minor > 0,
    );
  }
  return const CashOutAllowed();
}
