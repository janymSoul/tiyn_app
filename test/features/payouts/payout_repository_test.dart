import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/network/api_client.dart';
import 'package:tiyn_app/core/network/idempotency_key.dart';
import 'package:tiyn_app/features/payouts/data/payout_repository.dart';
import 'package:tiyn_app/features/payouts/data/payout_state.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/fakes.dart';

Map<String, Object?> _payout({String id = 'p1', String state = 'REQUESTED'}) =>
    {
      'id': id,
      'teenId': 'teen',
      'parentId': 'parent',
      'amount': 1000000,
      'currency': 'KZT',
      'state': state,
      'requestedAt': '2026-11-01T10:00:00Z',
      'expiresAt': '2026-11-08T10:00:00Z',
      'resolvedAt': null,
      'cancelReason': null,
    };

({PayoutRepository repository, FakeAdapter adapter, List<String> bodies}) _ok([
  Object? body,
]) {
  final bodies = <String>[];
  final adapter = FakeAdapter((_, sent) async {
    bodies.add(sent);
    return jsonBody(body ?? _payout());
  });
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = adapter;
  final api = ApiClient(
    baseUrl: Uri.parse('https://api.test'),
    tokens: FakeTokenStorage('token'),
    onUnauthorized: () {},
    dio: dio,
  );
  return (repository: PayoutRepository(api), adapter: adapter, bodies: bodies);
}

void main() {
  group('create', () {
    test('POST /payouts with the body and the Idempotency-Key', () async {
      final s = _ok();
      final p = await s.repository.create(
        parentId: 'parent',
        amount: const Money.kzt(1000000),
        key: const IdempotencyKey('key-1'),
      );
      expect(p.id, 'p1');
      final r = s.adapter.requests.single;
      expect(r.method, 'POST');
      expect(r.path, '/payouts');
      expect(r.headers['Idempotency-Key'], 'key-1');
      expect(jsonDecode(s.bodies.single), {
        'parentId': 'parent',
        'amount': 1000000,
      });
    });

    test('a retry with the same key sends the same header and body', () async {
      final s = _ok();
      const key = IdempotencyKey('same');
      for (var i = 0; i < 2; i++) {
        await s.repository.create(
          parentId: 'parent',
          amount: const Money.kzt(1000000),
          key: key,
        );
      }
      final [a, b] = s.adapter.requests;
      expect(a.headers['Idempotency-Key'], b.headers['Idempotency-Key']);
      expect(s.bodies[0], s.bodies[1]);
    });
  });

  group('list', () {
    test('no filter: GET /payouts without a query', () async {
      final s = _ok([_payout(id: 'a'), _payout(id: 'b')]);
      final list = await s.repository.list();
      expect(list.map((p) => p.id), ['a', 'b']);
      final r = s.adapter.requests.single;
      expect(r.method, 'GET');
      expect(r.path, '/payouts');
      expect(r.queryParameters, {'limit': 100});
    });

    test('the state is sent as the wire value', () async {
      final s = _ok(<Object?>[]);
      await s.repository.list(state: PayoutState.requested);
      expect(s.adapter.requests.single.queryParameters, {
        'state': 'REQUESTED',
        'limit': 100,
      });
    });

    test('envelope shape: items are parsed', () async {
      final s = _ok({
        'items': [_payout(id: 'a'), _payout(id: 'b')],
      });
      final list = await s.repository.list();
      expect(list.map((p) => p.id), ['a', 'b']);
      expect(s.adapter.requests, hasLength(1));
    });

    test('envelope with nextCursor: follows to the last page', () async {
      var n = 0;
      final adapter = FakeAdapter((_, _) async {
        n++;
        return jsonBody(
          n == 1
              ? {
                  'items': [_payout(id: 'a')],
                  'nextCursor': 'c1',
                }
              : {
                  'items': [_payout(id: 'b')],
                },
        );
      });
      final api = ApiClient(
        baseUrl: Uri.parse('https://api.test'),
        tokens: FakeTokenStorage('token'),
        onUnauthorized: () {},
        dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = adapter,
      );
      final list = await PayoutRepository(api)
          .list(state: PayoutState.requested);
      expect(list.map((p) => p.id), ['a', 'b']);
      expect(adapter.requests.last.queryParameters, {
        'state': 'REQUESTED',
        'limit': 100,
        'cursor': 'c1',
      });
    });
  });

  test('get: GET /payouts/{id}', () async {
    final s = _ok();
    await s.repository.get('p1');
    final r = s.adapter.requests.single;
    expect(r.method, 'GET');
    expect(r.path, '/payouts/p1');
  });

  group('fulfil, decline and cancel', () {
    test('each posts to its own path and sends no Idempotency-Key', () async {
      final s = _ok(_payout(state: 'FULFILLED'));
      await s.repository.fulfil('p1');
      await s.repository.decline('p1');
      await s.repository.cancel('p1');
      expect(s.adapter.requests.map((r) => (r.method, r.path)), [
        ('POST', '/payouts/p1/fulfil'),
        ('POST', '/payouts/p1/decline'),
        ('POST', '/payouts/p1/cancel'),
      ]);
      for (final r in s.adapter.requests) {
        expect(r.headers.containsKey('Idempotency-Key'), isFalse);
      }
    });

    test(
      'the real resolved response has no expiresAt and still decodes',
      () async {
        // What the backend sends for a fulfilled/declined payout.
        final body = _payout(state: 'FULFILLED')
          ..remove('expiresAt')
          ..['resolvedAt'] = '2026-11-02T10:00:00Z';
        final s = _ok(body);
        final p = await s.repository.fulfil('p1');
        expect(p.state, PayoutState.fulfilled);
        expect(p.expiresAt, isNull);
      },
    );
  });
}
