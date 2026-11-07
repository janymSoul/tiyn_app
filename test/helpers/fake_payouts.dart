import 'dart:async';

import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/idempotency_key.dart';
import 'package:tiyn_app/features/payouts/data/cancel_reason.dart';
import 'package:tiyn_app/features/payouts/data/payout.dart';
import 'package:tiyn_app/features/payouts/data/payout_repository.dart';
import 'package:tiyn_app/features/payouts/data/payout_state.dart';

Payout fakePayout({
  String id = 'po1',
  String teenId = 'teen1',
  String parentId = 'p1',
  Money amount = const Money.kzt(500000),
  PayoutState state = PayoutState.requested,
  DateTime? requestedAt,
  DateTime? expiresAt,
  CancelReason? cancelReason,
}) {
  final at = requestedAt ?? DateTime.utc(2026, 11, 7, 10);
  return Payout(
    id: id,
    teenId: teenId,
    parentId: parentId,
    amount: amount,
    state: state,
    requestedAt: at,
    expiresAt: expiresAt ?? at.add(const Duration(days: 7)),
    resolvedAt: state == PayoutState.requested ? null : at,
    cancelReason: cancelReason,
  );
}

typedef CreateCall = ({String parentId, Money amount, String key});

/// Records every call. Set [createError] / [fulfilError] ... to fail the next
/// calls, or [createGate] to hold a `create` open.
class FakePayoutRepository implements PayoutRepository {
  FakePayoutRepository([List<Payout> payouts = const []])
    : payouts = List.of(payouts);

  List<Payout> payouts;
  final creates = <CreateCall>[];
  Object? createError;
  Completer<void>? createGate;
  Object? listError;
  final listStates = <PayoutState?>[];
  final gets = <String>[];
  final cancels = <String>[];
  final fulfils = <String>[];
  final declines = <String>[];
  Object? fulfilError;
  Object? declineError;
  Completer<void>? fulfilGate;
  Object? getError;
  Object? cancelError;
  Completer<void>? cancelGate;
  Completer<void>? getGate;
  Completer<void>? listGate;

  @override
  Future<Payout> create({
    required String parentId,
    required Money amount,
    required IdempotencyKey key,
  }) async {
    creates.add((parentId: parentId, amount: amount, key: key.value));
    await createGate?.future;
    final failure = createError;
    if (failure != null) throw failure;
    return fakePayout(parentId: parentId, amount: amount);
  }

  @override
  Future<List<Payout>> list({PayoutState? state}) async {
    listStates.add(state);
    await listGate?.future;
    final failure = listError;
    if (failure != null) throw failure;
    return [
      for (final p in payouts)
        if (state == null || p.state == state) p,
    ];
  }

  @override
  Future<Payout> get(String id) async {
    gets.add(id);
    await getGate?.future;
    final failure = getError;
    if (failure != null) throw failure;
    final found = payouts.where((p) => p.id == id).firstOrNull;
    if (found == null) {
      throw const ApiException(code: 'not_found', statusCode: 404);
    }
    return found;
  }

  @override
  Future<Payout> fulfil(String id) async {
    fulfils.add(id);
    await fulfilGate?.future;
    final failure = fulfilError;
    if (failure != null) throw failure;
    return fakePayout(id: id, state: PayoutState.fulfilled);
  }

  @override
  Future<Payout> decline(String id) async {
    declines.add(id);
    final failure = declineError;
    if (failure != null) throw failure;
    return fakePayout(
      id: id,
      state: PayoutState.cancelled,
      cancelReason: CancelReason.declined,
    );
  }

  @override
  Future<Payout> cancel(String id) async {
    cancels.add(id);
    await cancelGate?.future;
    final failure = cancelError;
    if (failure != null) throw failure;
    return fakePayout(
      id: id,
      state: PayoutState.cancelled,
      cancelReason: CancelReason.teenCancelled,
    );
  }
}
