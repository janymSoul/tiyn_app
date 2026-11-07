import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/idempotency_key.dart';
import 'package:tiyn_app/core/network/idempotent_submit_controller.dart';
import 'package:tiyn_app/features/payouts/application/request_payout_controller.dart';
import 'package:tiyn_app/features/payouts/data/payout.dart';

import '../../helpers/fake_payouts.dart';

const _request = PayoutRequest(parentId: 'p1', amount: Money.kzt(500000));
const _other = PayoutRequest(parentId: 'p1', amount: Money.kzt(300000));

class _Sent {
  _Sent(this.request, this.key);
  final PayoutRequest request;
  final String key;
}

({RequestPayoutController controller, List<_Sent> sent, List<Object?> script})
_setup() {
  final sent = <_Sent>[];
  final script = <Object?>[];
  var n = 0;
  final controller = RequestPayoutController(
    send: (r, key) async {
      sent.add(_Sent(r, key.value));
      final next = script.isEmpty ? null : script.removeAt(0);
      if (next != null) throw next;
      return fakePayout(parentId: r.parentId, amount: r.amount);
    },
    newKey: () => IdempotencyKey('key-${++n}'),
  );
  return (controller: controller, sent: sent, script: script);
}

const _rejected = ApiException(code: 'insufficient_funds', statusCode: 422);
const _timeout = ApiException(code: 'timeout');
const _server = ApiException(code: 'internal_error', statusCode: 500);

void main() {
  test('the key is made when the form opens and a success keeps it', () async {
    final s = _setup();
    expect(s.controller.key.value, 'key-1');
    expect(await s.controller.submit(_request), isTrue);
    expect(s.sent.single.key, 'key-1');
    expect(s.controller.created, isA<Payout>());
  });

  test('a second submit while one is in flight is ignored', () async {
    final gate = Completer<void>();
    var calls = 0;
    final c = RequestPayoutController(
      send: (r, k) async {
        calls++;
        await gate.future;
        return fakePayout();
      },
    );
    final first = c.submit(_request);
    expect(await c.submit(_request), isFalse);
    gate.complete();
    await first;
    expect(calls, 1);
  });

  group('after a rejection (4xx)', () {
    test('nothing is pending; the first edit makes a new key, once', () async {
      final s = _setup()..script.add(_rejected);
      expect(await s.controller.submit(_request), isFalse);
      expect(s.controller.phase, SubmitPhase.rejected);
      expect(s.controller.pending, isNull);
      expect(s.controller.key.value, 'key-1');

      s.controller.noteEdited();
      expect(s.controller.key.value, 'key-2');
      s.controller.noteEdited();
      expect(
        s.controller.key.value,
        'key-2',
        reason: 'one rotation per failure',
      );

      await s.controller.submit(_other);
      expect(s.sent.last.key, 'key-2');
    });

    test('a second rejection allows another rotation', () async {
      final s = _setup()..script.addAll([_rejected, _rejected]);
      await s.controller.submit(_request);
      s.controller.noteEdited();
      await s.controller.submit(_other);
      s.controller.noteEdited();
      expect(s.controller.key.value, 'key-3');
    });

    test('an edit with no failure does not touch the key', () {
      final s = _setup();
      s.controller.noteEdited();
      expect(s.controller.key.value, 'key-1');
    });
  });

  group('after an ambiguous failure (timeout, network, 5xx)', () {
    test('locks, keeps the payload, and retries with the same key', () async {
      final s = _setup()..script.addAll([_timeout, _server]);
      expect(await s.controller.submit(_request), isFalse);
      expect(s.controller.phase, SubmitPhase.ambiguous);
      expect(s.controller.isLocked, isTrue);
      expect(s.controller.pending, _request);

      // Whatever the form holds now, the original payload is resent.
      expect(await s.controller.submit(_other), isFalse);
      expect(s.sent.map((e) => (e.request, e.key)), [
        (_request, 'key-1'),
        (_request, 'key-1'),
      ]);

      expect(await s.controller.submit(_other), isTrue);
      expect(s.sent.last.request, _request);
      expect(s.sent.last.key, 'key-1');
      expect(s.controller.phase, SubmitPhase.editing);
    });

    test('editing is not possible without the explicit unlock', () async {
      final s = _setup()..script.add(_timeout);
      await s.controller.submit(_request);
      s.controller.noteEdited();
      expect(s.controller.key.value, 'key-1');
    });

    test('unlockToEdit gives a new key and frees the fields', () async {
      final s = _setup()..script.add(_timeout);
      await s.controller.submit(_request);
      s.controller.unlockToEdit();
      expect(s.controller.phase, SubmitPhase.editing);
      expect(s.controller.isLocked, isFalse);
      expect(s.controller.key.value, 'key-2');
      await s.controller.submit(_other);
      expect(s.sent.last.key, 'key-2');
      expect(s.sent.last.request, _other);
    });

    test('unlockToEdit does nothing outside the ambiguous phase', () async {
      final s = _setup();
      s.controller.unlockToEdit();
      expect(s.controller.key.value, 'key-1');
    });
  });
}
