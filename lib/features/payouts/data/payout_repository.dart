import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/network/api_client.dart';
import 'package:tiyn_app/core/network/idempotency_key.dart';
import 'package:tiyn_app/core/network/json.dart';
import 'package:tiyn_app/core/network/paged_list.dart';
import 'package:tiyn_app/features/payouts/data/payout.dart';
import 'package:tiyn_app/features/payouts/data/payout_state.dart';

Payout _payout(Object? json) => Payout.fromJson(asMap(json));

class PayoutRepository {
  PayoutRepository(this._api);

  final ApiClient _api;

  /// [key] must be the same for retries of the same payload.
  Future<Payout> create({
    required String parentId,
    required Money amount,
    required IdempotencyKey key,
  }) => _api.post(
    '/payouts',
    body: {'parentId': parentId, 'amount': amount.minor},
    idempotencyKey: key,
    decode: _payout,
  );

  Future<List<Payout>> list({PayoutState? state}) => PagedListReader(_api)
      .readAll('/payouts', query: {'state': ?state?.wire}, decodeItem: _payout);

  Future<Payout> get(String id) => _api.get('/payouts/$id', decode: _payout);

  // fulfil, decline and cancel take no key: repeating them is safe (api.md).

  Future<Payout> fulfil(String id) =>
      _api.post('/payouts/$id/fulfil', decode: _payout);

  Future<Payout> decline(String id) =>
      _api.post('/payouts/$id/decline', decode: _payout);

  Future<Payout> cancel(String id) =>
      _api.post('/payouts/$id/cancel', decode: _payout);
}
