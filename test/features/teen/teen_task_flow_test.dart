import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/app/router/routes.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';
import 'package:tiyn_app/features/tasks/application/proof_upload.dart';
import 'package:tiyn_app/features/tasks/application/task_providers.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';
import 'package:tiyn_app/features/teen/application/dashboard_controller.dart';

import '../../helpers/fake_dashboard.dart';
import '../../helpers/fake_family.dart';
import '../../helpers/fake_tasks.dart';
import '../../helpers/pump_app.dart';

class _TeenAuth extends AuthController {
  @override
  Future<User?> build() async =>
      const User(id: 'teen1', role: Role.teen, displayName: 'Dana');
}

class _Picker implements PhotoPicker {
  @override
  Future<Uint8List?> pick(PhotoOrigin origin) async => Uint8List.fromList([1]);
}

class _Encoder implements PhotoEncoder {
  @override
  Future<Uint8List?> toJpeg(Uint8List source, {required int quality}) async =>
      Uint8List.fromList([7, 7]);
}

class _H {
  _H()
    : tasks = FakeTaskRepository([fakeTask(id: 'c1')]),
      dashboard = FakeDashboardRepository(
        fakeDashboard(chores: [fakeChore(id: 'c1')]),
      );

  final FakeTaskRepository tasks;
  final FakeDashboardRepository dashboard;

  List<Override> get overrides => [
    authControllerProvider.overrideWith(_TeenAuth.new),
    familyRepositoryProvider.overrideWithValue(
      FakeFamilyRepository([
        const FamilyMember(id: 'p1', role: Role.parent, displayName: 'Aigerim'),
      ]),
    ),
    dashboardRepositoryProvider.overrideWithValue(dashboard),
    taskRepositoryProvider.overrideWithValue(tasks),
    photoPickerProvider.overrideWithValue(_Picker()),
    photoEncoderProvider.overrideWithValue(_Encoder()),
  ];
}

void main() {
  testWidgets('home card opens the task; submitting a note sends it once', (
    tester,
  ) async {
    final h = _H();
    await pumpApp(tester, overrides: h.overrides);

    await tester.tap(find.text('Wash dishes'));
    await tester.pumpAndSettle();
    expect(routerOf(tester).state.matchedLocation, Routes.teenTask('c1'));
    expect(find.text('Submit proof'), findsOneWidget);

    await tester.tap(find.text('Submit proof'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Write a note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'All clean');
    await tester.pump();
    h.dashboard.dashboard = fakeDashboard(
      chores: [fakeChore(id: 'c1', state: TaskState.submitted)],
    );
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(h.tasks.submissions.single.text, 'All clean');
    expect(find.text('Waiting for your parent'), findsOneWidget);
    expect(find.text('Submit proof'), findsNothing);
  });

  testWidgets('a timeout offers Try again with the same key', (tester) async {
    final h = _H();
    var fail = true;
    h.tasks.onSubmit = () async {
      if (fail) throw const ApiException(code: 'timeout');
    };
    await pumpApp(tester, overrides: h.overrides);
    unawaited(routerOf(tester).push(Routes.teenTask('c1')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit proof'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(h.tasks.submissions, hasLength(2));
    expect(h.tasks.submissions[0].key, h.tasks.submissions[1].key);
    expect(h.tasks.submissions.last.photo, [7, 7]);
  });

  testWidgets('a redo request shows the parent note above the task', (
    tester,
  ) async {
    final h = _H();
    h.tasks.tasks = [
      fakeTask(id: 'c1').copyWith(decisionNote: 'Do the pans too'),
    ];
    await pumpApp(tester, overrides: h.overrides);
    unawaited(routerOf(tester).push(Routes.teenTask('c1')));
    await tester.pumpAndSettle();
    expect(find.text('Your parent asked you to redo this'), findsOneWidget);
    expect(find.text('Do the pans too'), findsOneWidget);
    expect(find.text('Submit proof'), findsOneWidget);
  });

  testWidgets('a rejected task shows no submit button', (tester) async {
    final h = _H();
    h.tasks.tasks = [
      fakeTask(
        id: 'c1',
        state: TaskState.rejected,
      ).copyWith(decisionNote: 'No'),
    ];
    await pumpApp(tester, overrides: h.overrides);
    unawaited(routerOf(tester).push(Routes.teenTask('c1')));
    await tester.pumpAndSettle();
    expect(find.text('Submit proof'), findsNothing);
    expect(find.text('Your parent rejected this task.'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);
  });

  group('milestone', () {
    _H milestone({required int approved, required int total}) {
      final h = _H();
      h.dashboard.dashboard = fakeDashboard(
        milestones: [
          fakeMilestone(id: 'm1', approvedTasks: approved, totalTasks: total),
        ],
        chores: [
          for (var i = 0; i < total; i++)
            fakeChore(
              id: 's$i',
              title: 'Step $i',
              milestoneId: 'm1',
              state: i < approved ? TaskState.approved : TaskState.assigned,
            ),
        ],
      );
      return h;
    }

    testWidgets(
      'submit is disabled with the reason until all steps are approved',
      (tester) async {
        final h = milestone(approved: 1, total: 3);
        await pumpApp(tester, overrides: h.overrides);
        unawaited(routerOf(tester).push(Routes.teenMilestone('m1')));
        await tester.pumpAndSettle();

        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull);
        expect(
          find.text('Finish all steps first. 1 of 3 approved.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('submit is enabled once every step is approved', (
      tester,
    ) async {
      final h = milestone(approved: 2, total: 2);
      await pumpApp(tester, overrides: h.overrides);
      unawaited(routerOf(tester).push(Routes.teenMilestone('m1')));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('a step opens its task', (tester) async {
      final h = milestone(approved: 0, total: 1);
      h.tasks.tasks = [fakeTask(id: 's0', title: 'Step 0')];
      await pumpApp(tester, overrides: h.overrides);
      unawaited(routerOf(tester).push(Routes.teenMilestone('m1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Step 0'));
      await tester.pumpAndSettle();
      expect(routerOf(tester).state.matchedLocation, Routes.teenTask('s0'));
    });
  });
}
