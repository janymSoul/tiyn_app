import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/app/app.dart';
import 'package:tiyn_app/core/push/push_messaging.dart';
import 'package:tiyn_app/core/push/push_providers.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';
import 'package:tiyn_app/features/push/application/device_registration.dart';
import 'package:tiyn_app/features/push/presentation/notify_prompt_sheet.dart';
import 'package:tiyn_app/features/teen/application/dashboard_controller.dart';

import '../../helpers/fake_dashboard.dart';
import '../../helpers/fake_family.dart';
import '../../helpers/fake_push_backend.dart';
import '../../helpers/fake_push_messaging.dart';
import '../../helpers/parent_harness.dart';
import '../../helpers/pump_app.dart';

// The same worst case as test/app/layout_test.dart: 360x640, 1.3x text, ru and
// kk. Fixed by wrapping or scrolling, never by shrinking fonts.

void _smallPhone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(360, 640)
    ..devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearAllTestValues();
  });
}

class _TeenAuth extends AuthController {
  @override
  Future<User?> build() async =>
      const User(id: 'teen1', role: Role.teen, displayName: 'Данияр Серікұлы');
}

List<Override> _teen(FakePushMessaging push) => [
  authControllerProvider.overrideWith(_TeenAuth.new),
  familyRepositoryProvider.overrideWithValue(
    FakeFamilyRepository([
      const FamilyMember(
        id: 'p1',
        role: Role.parent,
        displayName: 'Айгерім Нұрланқызы',
      ),
    ]),
  ),
  dashboardRepositoryProvider.overrideWithValue(FakeDashboardRepository()),
  pushMessagingProvider.overrideWithValue(push),
  pushStoreProvider.overrideWithValue(FakePushStore()),
  deviceRepositoryProvider.overrideWithValue(FakeDeviceRepository()),
];

const _longPush = PushMessage(
  title: 'Данияр Серікұлы жаңа растама жіберді: тексеріп көріңіз',
  body: 'Вымыть всю посуду после большого ужина и протереть стол и плиту до блеска, пожалуйста',
  data: {'type': 'TASK_SUBMITTED', 'taskId': 't1'},
);

void main() {
  for (final locale in const ['ru', 'kk']) {
    group('no overflow in $locale at 360x640, 1.3x text:', () {
      testWidgets('banner with a long title and body', (tester) async {
        _smallPhone(tester);
        final push = FakePushMessaging();
        await pumpApp(tester, overrides: _teen(push), locale: Locale(locale));

        push.emitForeground(_longPush);
        await tester.pump();
        await tester.pump();

        expect(find.byIcon(Icons.close), findsOneWidget);
        final banner = tester.getRect(find.byType(Dismissible));
        expect(banner.left, greaterThanOrEqualTo(0));
        expect(banner.right, lessThanOrEqualTo(360));
        expect(banner.bottom, lessThan(300), reason: 'stays at the top');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 6));
      });

      testWidgets('the soft card and the denied card on the teen home', (
        tester,
      ) async {
        _smallPhone(tester);
        final push = FakePushMessaging(permission: PushPermission.notDetermined)
          ..permissionAfterRequest = PushPermission.denied;
        await pumpApp(tester, overrides: _teen(push), locale: Locale(locale));
        expect(find.byType(FilledButton), findsOneWidget, reason: 'ask card');
        expect(tester.takeException(), isNull);

        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        expect(
          find.byType(FilledButton),
          findsOneWidget,
          reason: 'denied card',
        );
        expect(find.byType(TextButton), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('the parent sheet with a long name', (tester) async {
        _smallPhone(tester);
        final push = FakePushMessaging(
          permission: PushPermission.notDetermined,
        );
        final h = ParentHarness(
          teens: [(id: 'teen1', name: 'Данияр Серікұлы')],
        );
        await pumpApp(
          tester,
          overrides: [
            ...h.overrides,
            pushMessagingProvider.overrideWithValue(push),
            pushStoreProvider.overrideWithValue(FakePushStore()),
            deviceRepositoryProvider.overrideWithValue(FakeDeviceRepository()),
          ],
          locale: Locale(locale),
        );

        final anchor = tester.element(find.byType(NavigationBar));
        final container = ProviderScope.containerOf(
          tester.element(find.byType(TiynApp)),
        );

        final shown = askForNotificationsAfterCreate(
          navigatorContext: Navigator.of(anchor, rootNavigator: true).context,
          container: container,
          teenName: 'Данияр Серікұлы Ярославович',
        );
        await tester.pumpAndSettle();

        final turnOn = find.byType(FilledButton);
        expect(turnOn, findsOneWidget);
        expect(tester.getRect(turnOn).bottom, lessThanOrEqualTo(640));
        expect(tester.takeException(), isNull);

        await tester.tap(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(TextButton),
          ),
        );
        await tester.pumpAndSettle();
        await shown;
      });
    });
  }

  group('semantics', () {
    testWidgets('the banner is a live region with a labelled close button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final push = FakePushMessaging();
      await pumpApp(tester, overrides: _teen(push));

      push.emitForeground(
        const PushMessage(title: 'Task approved', body: '+1 500 ₸'),
      );
      await tester.pump();
      await tester.pump();

      expect(find.bySemanticsLabel('Task approved. +1 500 ₸'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Task approved. +1 500 ₸')),
        isSemantics(label: 'Task approved. +1 500 ₸', isLiveRegion: true),
      );
      expect(find.bySemanticsLabel('Dismiss'), findsOneWidget);
      expect(find.bySemanticsLabel('Open'), findsOneWidget);
      await tester.pump(const Duration(seconds: 13));
      handle.dispose();
    });

    testWidgets('the cards have a header and reachable actions', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final push = FakePushMessaging(permission: PushPermission.notDetermined);
      await pumpApp(tester, overrides: _teen(push));

      expect(
        tester.getSemantics(
          find.bySemanticsLabel('Get notified about new tasks and money'),
        ),
        isSemantics(
          label: 'Get notified about new tasks and money',
          isHeader: true,
        ),
      );
      expect(find.bySemanticsLabel('Turn on'), findsOneWidget);
      expect(find.bySemanticsLabel('Not now'), findsOneWidget);
      handle.dispose();
    });
  });
}
