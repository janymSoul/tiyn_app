import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/push/notification_settings_opener.dart';
import 'package:tiyn_app/core/push/push_messaging.dart';
import 'package:tiyn_app/core/push/push_providers.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';
import 'package:tiyn_app/features/push/application/device_registration.dart';
import 'package:tiyn_app/features/push/application/push_prompt.dart';
import 'package:tiyn_app/features/push/presentation/notify_prompt_sheet.dart';
import 'package:tiyn_app/features/teen/application/dashboard_controller.dart';

import '../../helpers/fake_dashboard.dart';
import '../../helpers/fake_family.dart';
import '../../helpers/fake_push_backend.dart';
import '../../helpers/fake_push_messaging.dart';
import '../../helpers/parent_harness.dart';
import '../../helpers/pump_app.dart';

class _TeenAuth extends AuthController {
  _TeenAuth(this._id);

  final String _id;

  @override
  Future<User?> build() async =>
      User(id: _id, role: Role.teen, displayName: 'Dana');
}

class _Opener implements NotificationSettingsOpener {
  int opened = 0;

  @override
  Future<void> open() async => opened++;
}

/// The pieces that survive an app restart.
class _Phone {
  final store = FakePushStore();
  final opener = _Opener();
}

List<Override> _teen(
  _Phone phone,
  FakePushMessaging push, {
  String userId = 'teen1',
}) => [
  authControllerProvider.overrideWith(() => _TeenAuth(userId)),
  familyRepositoryProvider.overrideWithValue(
    FakeFamilyRepository([
      const FamilyMember(id: 'p1', role: Role.parent, displayName: 'Aigerim'),
    ]),
  ),
  dashboardRepositoryProvider.overrideWithValue(FakeDashboardRepository()),
  pushMessagingProvider.overrideWithValue(push),
  pushStoreProvider.overrideWithValue(phone.store),
  deviceRepositoryProvider.overrideWithValue(FakeDeviceRepository()),
  notificationSettingsOpenerProvider.overrideWithValue(phone.opener),
];

const _askTitle = 'Get notified about new tasks and money';
const _deniedTitle = 'Notifications are off';

void main() {
  notifyPromptOrderingTests();
  group('teen home', () {
    testWidgets('asks once with a bottom sheet, when never asked', (
      tester,
    ) async {
      final phone = _Phone();
      final push = FakePushMessaging(permission: PushPermission.notDetermined);
      await pumpApp(tester, overrides: _teen(phone, push));

      expect(find.text(_askTitle), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(push.requestPermissionCalls, 0, reason: 'explanation first');
    });

    testWidgets('Turn on asks the system and the sheet closes', (tester) async {
      final phone = _Phone();
      final push = FakePushMessaging(permission: PushPermission.notDetermined);
      await pumpApp(tester, overrides: _teen(phone, push));

      await tester.tap(find.text('Turn on'));
      await tester.pumpAndSettle();

      expect(push.requestPermissionCalls, 1);
      expect(find.text(_askTitle), findsNothing);
      expect(find.text(_deniedTitle), findsNothing);
    });

    testWidgets(
      'Not now never asks the system and is remembered after a restart',
      (tester) async {
        final phone = _Phone();
        final push = FakePushMessaging(
          permission: PushPermission.notDetermined,
        );
        await pumpApp(tester, overrides: _teen(phone, push));

        await tester.tap(find.text('Not now'));
        await tester.pumpAndSettle();
        expect(find.text(_askTitle), findsNothing);
        expect(push.requestPermissionCalls, 0);

        await tester.pumpWidget(const SizedBox());
        await pumpApp(tester, overrides: _teen(phone, push));
        expect(find.text(_askTitle), findsNothing);
        expect(
          find.text(_deniedTitle),
          findsNothing,
          reason: 'nothing was denied',
        );
      },
    );

    testWidgets('nothing is shown when notifications are already on', (
      tester,
    ) async {
      final phone = _Phone();
      final push = FakePushMessaging();
      await pumpApp(tester, overrides: _teen(phone, push));
      expect(find.text(_askTitle), findsNothing);
      expect(find.text(_deniedTitle), findsNothing);
    });

    testWidgets(
      'denied before we ever asked (older Android setting): no card',
      (tester) async {
        final phone = _Phone();
        final push = FakePushMessaging(permission: PushPermission.denied);
        await pumpApp(tester, overrides: _teen(phone, push));
        expect(find.text(_askTitle), findsNothing);
        expect(find.text(_deniedTitle), findsNothing);
      },
    );

    testWidgets('the prompt is per user on a shared phone', (tester) async {
      final phone = _Phone();
      final push = FakePushMessaging(permission: PushPermission.notDetermined);
      await pumpApp(tester, overrides: _teen(phone, push, userId: 'teen1'));
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(phone.store.flags, contains('explained_teen1'));

      await tester.pumpWidget(const SizedBox());
      await pumpApp(tester, overrides: _teen(phone, push, userId: 'teen2'));
      expect(find.text(_askTitle), findsOneWidget);
    });
  });

  group('after the system said no', () {
    Future<_Phone> deny(WidgetTester tester, FakePushMessaging push) async {
      final phone = _Phone();
      push.permissionAfterRequest = PushPermission.denied;
      await pumpApp(tester, overrides: _teen(phone, push));
      await tester.tap(find.text('Turn on'));
      await tester.pumpAndSettle();
      return phone;
    }

    testWidgets('one card offers the settings; the app still works', (
      tester,
    ) async {
      final push = FakePushMessaging(permission: PushPermission.notDetermined);
      final phone = await deny(tester, push);

      expect(find.text(_deniedTitle), findsOneWidget);
      expect(find.text('Hi, Dana'), findsOneWidget);

      await tester.tap(find.text('Open settings'));
      await tester.pump();
      expect(phone.opener.opened, 1);
    });

    testWidgets('dismissing it is remembered for good, across a restart', (
      tester,
    ) async {
      final push = FakePushMessaging(permission: PushPermission.notDetermined);
      final phone = await deny(tester, push);

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text(_deniedTitle), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await pumpApp(tester, overrides: _teen(phone, push));
      expect(find.text(_deniedTitle), findsNothing);
      expect(find.text(_askTitle), findsNothing);
    });

    testWidgets('it comes back after a restart if it was not dismissed', (
      tester,
    ) async {
      final push = FakePushMessaging(permission: PushPermission.notDetermined);
      final phone = await deny(tester, push);

      await tester.pumpWidget(const SizedBox());
      await pumpApp(tester, overrides: _teen(phone, push));
      expect(find.text(_deniedTitle), findsOneWidget);
    });

    testWidgets('it goes away by itself when they turn it on in settings', (
      tester,
    ) async {
      final push = FakePushMessaging(permission: PushPermission.notDetermined);
      await deny(tester, push);
      expect(find.text(_deniedTitle), findsOneWidget);

      push.permission = PushPermission.granted;
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();

      expect(find.text(_deniedTitle), findsNothing);
    });
  });

  group('parent', () {
    List<Override> parent(_Phone phone, FakePushMessaging push) {
      final h = ParentHarness(teens: [(id: 'teen1', name: 'Dana')]);
      return [
        ...h.overrides,
        pushMessagingProvider.overrideWithValue(push),
        pushStoreProvider.overrideWithValue(phone.store),
        deviceRepositoryProvider.overrideWithValue(FakeDeviceRepository()),
        notificationSettingsOpenerProvider.overrideWithValue(phone.opener),
      ];
    }

    Future<void> createTask(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(400, 1100)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.tap(find.text('New task'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Wash');
      await tester.enterText(
        find.widgetWithText(TextField, 'Reward (₸)'),
        '1 500',
      );
      await tester.pump();
      await tester.tap(find.text('Add task'));
      await tester.pumpAndSettle();
    }

    const sheetTitle = 'Get notified when Dana sends proof';

    testWidgets('no card on the parent home before anything is asked', (
      tester,
    ) async {
      final push = FakePushMessaging(permission: PushPermission.notDetermined);
      await pumpApp(tester, overrides: parent(_Phone(), push));
      expect(find.text(_askTitle), findsNothing);
      expect(find.text(sheetTitle), findsNothing);
      expect(push.requestPermissionCalls, 0);
    });

    testWidgets(
      'right after a task is created: our explanation, then the system dialog',
      (tester) async {
        final push = FakePushMessaging(
          permission: PushPermission.notDetermined,
        );
        await pumpApp(tester, overrides: parent(_Phone(), push));
        await createTask(tester);

        expect(routerOf(tester).state.matchedLocation, '/parent/home');
        expect(find.text(sheetTitle), findsOneWidget);
        expect(push.requestPermissionCalls, 0, reason: 'explanation first');

        await tester.tap(find.text('Turn on'));
        await tester.pumpAndSettle();

        expect(push.requestPermissionCalls, 1);
        expect(find.text(sheetTitle), findsNothing);
      },
    );

    testWidgets('shown once: a second task does not ask again', (tester) async {
      final push = FakePushMessaging(permission: PushPermission.notDetermined);
      await pumpApp(tester, overrides: parent(_Phone(), push));
      await createTask(tester);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(push.requestPermissionCalls, 0);

      await createTask(tester);
      expect(find.text(sheetTitle), findsNothing);
    });

    testWidgets('not shown when notifications are already on', (tester) async {
      final push = FakePushMessaging();
      await pumpApp(tester, overrides: parent(_Phone(), push));
      await createTask(tester);
      expect(find.text(sheetTitle), findsNothing);
    });

    testWidgets('a denial shows the settings card on the parent home', (
      tester,
    ) async {
      final push = FakePushMessaging(permission: PushPermission.notDetermined)
        ..permissionAfterRequest = PushPermission.denied;
      await pumpApp(tester, overrides: parent(_Phone(), push));
      await createTask(tester);
      await tester.tap(find.text('Turn on'));
      await tester.pumpAndSettle();

      expect(find.text(_deniedTitle), findsOneWidget);
    });
  });
}

void notifyPromptOrderingTests() {
  testWidgets('"explained" is not saved when the sheet never shows', (
    tester,
  ) async {
    final phone = _Phone();
    final push = FakePushMessaging(permission: PushPermission.notDetermined);
    late BuildContext captured;
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        authControllerProvider.overrideWith(() => _TeenAuth('teen1')),
        pushMessagingProvider.overrideWithValue(push),
        pushStoreProvider.overrideWithValue(phone.store),
      ],
    );
    addTearDown(container.dispose);
    container.listen(authControllerProvider, (_, _) {});
    await container.read(authControllerProvider.future);
    container.listen(pushPromptProvider, (_, _) {});
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          captured = context;
          return const SizedBox();
        },
      ),
    );
    await tester.pumpWidget(const SizedBox());

    final asking = askTeenForNotifications(
      navigatorContext: captured,
      container: container,
    );
    await tester.pump();
    await tester.pump();
    await asking;

    expect(phone.store.flags, isEmpty);
  });
}
