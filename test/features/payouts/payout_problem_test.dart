import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/features/payouts/application/payout_problem.dart';

PayoutProblem _of(String code, [int? status]) =>
    PayoutProblem.from(ApiException(code: code, statusCode: status));

void main() {
  test('every documented payout code maps to its problem', () {
    expect(_of('amount_too_small', 422), PayoutProblem.amountTooSmall);
    expect(_of('insufficient_funds', 422), PayoutProblem.insufficientFunds);
    expect(_of('payout_already_open', 409), PayoutProblem.alreadyOpen);
    expect(_of('invalid_amount', 422), PayoutProblem.invalidAmount);
    expect(_of('parent_required', 422), PayoutProblem.parentRequired);
    expect(_of('forbidden', 403), PayoutProblem.notLinked);
    expect(_of('not_found', 404), PayoutProblem.notFound);
    expect(_of('invalid_transition', 409), PayoutProblem.changed);
  });

  test('network, timeout and 5xx are ambiguous: the call may have landed', () {
    expect(_of('network_error'), PayoutProblem.ambiguous);
    expect(_of('timeout'), PayoutProblem.ambiguous);
    expect(_of('internal_error', 500), PayoutProblem.ambiguous);
    expect(_of('internal_error', 503).isAmbiguous, isTrue);
  });

  test('a definite rejection is not ambiguous', () {
    expect(_of('insufficient_funds', 422).isAmbiguous, isFalse);
    expect(_of('invalid_idempotency_key', 422), PayoutProblem.other);
    expect(_of('invalid_idempotency_key', 422).isAmbiguous, isFalse);
  });

  test('anything that is not an ApiException is "other"', () {
    expect(PayoutProblem.from(StateError('x')), PayoutProblem.other);
  });
}
