import 'package:tiyn_app/core/network/api_exception.dart';

/// What went wrong with a payout call, in the screen's terms. One mapping for
/// both roles; the copy differs per screen (a teen and a parent read
/// `insufficientFunds` differently).
enum PayoutProblem {
  amountTooSmall,
  insufficientFunds,
  alreadyOpen,
  invalidAmount,
  parentRequired,
  notLinked,
  notFound,

  /// 409 `invalid_transition`: somebody answered or cancelled it meanwhile.
  changed,

  /// The call may or may not have reached the server.
  ambiguous,
  other;

  static PayoutProblem from(Object error) {
    if (error is! ApiException) return other;
    return switch (error.code) {
      'amount_too_small' => amountTooSmall,
      'insufficient_funds' => insufficientFunds,
      'payout_already_open' => alreadyOpen,
      'invalid_amount' => invalidAmount,
      'parent_required' => parentRequired,
      'forbidden' => notLinked,
      'not_found' => notFound,
      'invalid_transition' => changed,
      _ when error.isRetryable => ambiguous,
      _ => other,
    };
  }

  /// The first attempt may exist on the server, so a retry must reuse the same
  /// idempotency key and the same payload.
  bool get isAmbiguous => this == ambiguous;
}
