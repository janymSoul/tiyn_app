import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/push/push_messaging.dart';
import 'package:tiyn_app/core/push/push_payload.dart';
import 'package:tiyn_app/core/push/push_type.dart';

import '../../helpers/fake_push_messaging.dart';

void main() {
  group('PushPayload', () {
    test('every wire name round-trips to its type', () {
      for (final type in PushType.values) {
        expect(PushPayload.fromData({'type': type.wire}).type, type);
      }
    });

    test('wire names are unique', () {
      expect(
        PushType.values.map((t) => t.wire).toSet().length,
        PushType.values.length,
      );
    });

    test('reads the ids', () {
      final p = PushPayload.fromData({'type': 'TASK_APPROVED', 'taskId': 't1'});
      expect(p.taskId, 't1');
      expect(p.payoutId, isNull);
      expect(
        PushPayload.fromData({'type': 'PAYOUT_FULFILLED', 'payoutId': 'p9'})
            .payoutId,
        'p9',
      );
    });

    test('an unknown type is null, not an error', () {
      expect(PushPayload.fromData({'type': 'SOMETHING_NEW'}).type, isNull);
    });

    test('missing, empty and blank values are null', () {
      expect(PushPayload.fromData(const {}).type, isNull);
      final p = PushPayload.fromData({
        'type': '  ',
        'taskId': ' ',
        'payoutId': '',
      });
      expect(p.type, isNull);
      expect(p.taskId, isNull);
      expect(p.payoutId, isNull);
    });

    test('ignores extra keys and trims', () {
      final p = PushPayload.fromData({
        'type': ' TASK_SUBMITTED ',
        'taskId': ' t1 ',
        'x': 'y',
      });
      expect(p.type, PushType.taskSubmitted);
      expect(p.taskId, 't1');
    });

    test('PushMessage exposes its payload', () {
      const m = PushMessage(data: {'type': 'FAMILY_UNLINKED'});
      expect(m.payload.type, PushType.familyUnlinked);
    });
  });

  group('FakePushMessaging', () {
    test('delivers each stream and the initial message', () async {
      final fake = FakePushMessaging()..initial = const PushMessage(title: 'x');
      final refreshed = <String>[];
      final foreground = <PushMessage>[];
      final opened = <PushMessage>[];
      fake.onTokenRefresh.listen(refreshed.add);
      fake.onForegroundMessage.listen(foreground.add);
      fake.onOpenedMessage.listen(opened.add);

      fake.emitTokenRefresh('t2');
      fake.emitForeground(const PushMessage(title: 'a'));
      fake.emitOpened(const PushMessage(title: 'b'));
      await Future<void>.delayed(Duration.zero);

      expect(refreshed, ['t2']);
      expect(foreground.single.title, 'a');
      expect(opened.single.title, 'b');
      expect((await fake.initialMessage())?.title, 'x');
    });

    test('request moves the status; delete drops the token', () async {
      final fake = FakePushMessaging(permission: PushPermission.notDetermined)
        ..permissionAfterRequest = PushPermission.denied;
      expect(await fake.requestPermission(), PushPermission.denied);
      expect(await fake.permissionStatus(), PushPermission.denied);
      await fake.deleteToken();
      expect(await fake.token(), isNull);
      expect(fake.deleteTokenCalls, 1);
    });
  });
}
