import 'package:flutter/foundation.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/network/idempotent_submit_controller.dart';
import 'package:tiyn_app/features/payouts/data/payout.dart';

@immutable
class PayoutRequest {
  const PayoutRequest({required this.parentId, required this.amount});

  final String parentId;
  final Money amount;

  @override
  bool operator ==(Object other) =>
      other is PayoutRequest &&
      other.parentId == parentId &&
      other.amount == amount;

  @override
  int get hashCode => Object.hash(parentId, amount);
}

/// Requesting a cash-out: the key rules are in [IdempotentSubmitController].
class RequestPayoutController
    extends IdempotentSubmitController<PayoutRequest, Payout> {
  RequestPayoutController({required super.send, super.newKey});
}
