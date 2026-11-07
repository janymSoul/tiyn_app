import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/features/payouts/data/cancel_reason.dart';
import 'package:tiyn_app/features/payouts/data/payout.dart';
import 'package:tiyn_app/features/payouts/data/payout_state.dart';

Map<String, Object?> _json({
  String state = 'REQUESTED',
  Object? resolvedAt,
  Object? cancelReason,
}) => {
  'id': 'p1',
  'teenId': 'teen',
  'parentId': 'parent',
  'amount': 1000000,
  'currency': 'KZT',
  'state': state,
  'requestedAt': '2026-11-01T10:00:00Z',
  'expiresAt': '2026-11-08T10:00:00Z',
  'resolvedAt': resolvedAt,
  'cancelReason': cancelReason,
};

Matcher _invalidResponse() => throwsA(
  isA<ApiException>().having((e) => e.code, 'code', 'invalid_response'),
);

void main() {
  group('Payout.fromJson', () {
    test('an open request', () {
      final p = Payout.fromJson(_json());
      expect(p.id, 'p1');
      expect(p.teenId, 'teen');
      expect(p.parentId, 'parent');
      expect(p.amount, const Money.kzt(1000000));
      expect(p.state, PayoutState.requested);
      expect(p.requestedAt, DateTime.utc(2026, 11, 1, 10));
      expect(p.expiresAt, DateTime.utc(2026, 11, 8, 10));
      expect(p.resolvedAt, isNull);
      expect(p.cancelReason, isNull);
    });

    test('a cancelled request keeps its reason and resolution time', () {
      final p = Payout.fromJson(
        _json(
          state: 'CANCELLED',
          resolvedAt: '2026-11-02T09:00:00Z',
          cancelReason: 'DECLINED',
        ),
      );
      expect(p.state, PayoutState.cancelled);
      expect(p.cancelReason, CancelReason.declined);
      expect(p.resolvedAt, DateTime.utc(2026, 11, 2, 9));
    });

    test('round-trips through toJson', () {
      for (final json in [
        _json(),
        _json(state: 'FULFILLED', resolvedAt: '2026-11-02T09:00:00Z'),
        _json(
          state: 'CANCELLED',
          resolvedAt: '2026-11-02T09:00:00Z',
          cancelReason: 'EXPIRED',
        ),
      ]) {
        final p = Payout.fromJson(json);
        expect(Payout.fromJson(p.toJson()), p);
      }
    });

    test('every wire value of both enums is known', () {
      for (final r in CancelReason.values) {
        expect(CancelReason.fromWire(r.wire), r);
      }
      for (final s in PayoutState.values) {
        expect(PayoutState.fromWire(s.wire), s);
      }
    });

    test('an unknown state or reason fails loudly', () {
      expect(() => Payout.fromJson(_json(state: 'PAID')), _invalidResponse());
      expect(
        () => Payout.fromJson(_json(state: 'CANCELLED', cancelReason: 'LOST')),
        _invalidResponse(),
      );
    });

    test('a missing field or a foreign currency fails loudly', () {
      for (final key in ['id', 'teenId', 'parentId', 'amount', 'expiresAt']) {
        final json = _json()..remove(key);
        expect(() => Payout.fromJson(json), _invalidResponse(), reason: key);
      }
      expect(
        () => Payout.fromJson({..._json(), 'currency': 'USD'}),
        _invalidResponse(),
      );
    });
  });
}
