import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/network/json.dart';
import 'package:tiyn_app/features/payouts/data/cancel_reason.dart';
import 'package:tiyn_app/features/payouts/data/payout_state.dart';

part 'payout.freezed.dart';

/// `PayoutResponse`. Decoded by hand because the amount is two fields
/// (`amount` + `currency`) that become one [Money].
///
/// [expiresAt] is sent only while [state] is `REQUESTED`: the backend omits
/// it once the payout is fulfilled or cancelled, so it is null then.
@freezed
abstract class Payout with _$Payout {
  const factory Payout({
    required String id,
    required String teenId,
    required String parentId,
    required Money amount,
    required PayoutState state,
    required DateTime requestedAt,
    DateTime? expiresAt,
    DateTime? resolvedAt,
    CancelReason? cancelReason,
  }) = _Payout;

  factory Payout.fromJson(Map<String, Object?> json) {
    final reason = json['cancelReason'];
    final state = PayoutState.fromWire(json['state']);
    return Payout(
      id: reqString(json, 'id'),
      teenId: reqString(json, 'teenId'),
      parentId: reqString(json, 'parentId'),
      amount: Money.fromJson(json['amount'], json['currency']),
      state: state,
      requestedAt: reqTime(json, 'requestedAt'),
      expiresAt: state.isOpen ? reqTime(json, 'expiresAt') : null,
      resolvedAt: optTime(json, 'resolvedAt'),
      cancelReason: reason == null ? null : CancelReason.fromWire(reason),
    );
  }
}

extension PayoutJson on Payout {
  /// The wire shape. Null fields are sent as `null`, as the backend does.
  Map<String, Object?> toJson() => {
    'id': id,
    'teenId': teenId,
    'parentId': parentId,
    'amount': amount.minor,
    'currency': amount.currency,
    'state': state.wire,
    'requestedAt': requestedAt.toUtc().toIso8601String(),
    'expiresAt': expiresAt?.toUtc().toIso8601String(),
    'resolvedAt': resolvedAt?.toUtc().toIso8601String(),
    'cancelReason': cancelReason?.wire,
  };
}
