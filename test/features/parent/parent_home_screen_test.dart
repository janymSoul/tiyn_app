import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/tasks/application/task_providers.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

import '../../helpers/fake_family.dart';
import '../../helpers/fake_tasks.dart';
import '../../helpers/pump_app.dart';

class _Auth extends AuthController {
  @override
  Future<User?> build() async => const User(
    id: 'parent1',
    role: Role.parent,
    displayName: 'Aigerim',
    joinCode: 'SXVPUR',
  );
}

class _Setup {
  _Setup({List<FamilyMemberSeed> teens = const []})
    : family = FakeFamilyRepository([
        for (final t in teens) teenMember(t.id, t.name),
      ]),
      taskRepository = FakeTaskRepository();

  final FakeFamilyRepository family;
  final FakeTaskRepository taskRepository;

  List<Override> get overrides => [
    authControllerProvider.overrideWith(_Auth.new),
    familyRepositoryProvider.overrideWithValue(family),
    taskRepositoryProvider.overrideWithValue(taskRepository),
  ];
}

typedef FamilyMemberSeed = ({String id, String name});

const _dana = (id: 'teen1', name: 'Dana');
const _aibek = (id: 'teen2', name: 'Aibek');
const _madina = (id: 'teen3', name: 'Madina');

void _background(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
}

Future<void> _foreground(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpAndSettle();
}

Future<void> _pullToRefresh(WidgetTester tester) async {
  await tester.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
  await tester.pumpAndSettle();
}

void main() {
  group('teen list', () {
    testWidgets('shows each teen with a status, to-check first', (
      tester,
    ) async {
      final s = _Setup(teens: [_madina, _dana, _aibek]);
      s.taskRepository.tasks = [
        fakeTask(id: 's1', teenId: 'teen3', state: TaskState.submitted),
        fakeTask(id: 's2', teenId: 'teen3', state: TaskState.submitted),
        fakeTask(id: 'a1', teenId: 'teen2'),
        fakeTask(id: 'a2', teenId: 'teen2'),
        fakeTask(id: 'a3', teenId: 'teen2'),
      ];
      await pumpApp(tester, overrides: s.overrides);

      expect(find.text('My teens'), findsOneWidget);
      expect(find.text('2 to check'), findsOneWidget);
      expect(find.text('3 active'), findsOneWidget);
      expect(find.text('Nothing active'), findsOneWidget);

      double top(String name) => tester.getTopLeft(find.text(name)).dy;
      expect(top('Madina'), lessThan(top('Aibek')));
      expect(top('Aibek'), lessThan(top('Dana')));
    });

    testWidgets('asks for the two filtered lists, never the full history', (
      tester,
    ) async {
      final s = _Setup(teens: [_dana]);
      await pumpApp(tester, overrides: s.overrides);

      expect(s.taskRepository.requests, hasLength(2));
      expect(s.taskRepository.callsFor(TaskState.submitted), 1);
      expect(s.taskRepository.callsFor(TaskState.assigned), 1);
      expect(s.taskRepository.callsFor(null), 0);
      expect(s.taskRepository.requests.every((r) => r.teenId == null), isTrue);
    });

    testWidgets('a teen without tasks says nothing is active', (tester) async {
      final s = _Setup(teens: [_dana]);
      await pumpApp(tester, overrides: s.overrides);
      expect(find.text('Nothing active'), findsOneWidget);
    });

    testWidgets('a failed task load explains itself and retries', (
      tester,
    ) async {
      final s = _Setup(teens: [_dana]);
      s.taskRepository.error = const ApiException(code: 'network_error');
      await pumpApp(tester, overrides: s.overrides);

      expect(find.text('Dana'), findsOneWidget);
      expect(find.text('No connection. Check your network.'), findsOneWidget);
      expect(find.text('Nothing active'), findsNothing);

      s.taskRepository.error = null;
      s.taskRepository.tasks = [fakeTask(teenId: 'teen1')];
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('1 active'), findsOneWidget);
      expect(find.text('No connection. Check your network.'), findsNothing);
    });

    testWidgets('a failed family load shows an error with retry', (
      tester,
    ) async {
      final s = _Setup();
      s.family.error = const ApiException(code: 'network_error');
      await pumpApp(tester, overrides: s.overrides);
      expect(find.text('No connection. Check your network.'), findsOneWidget);

      s.family
        ..error = null
        ..members_ = [teenMember('teen1', 'Dana')];
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Dana'), findsOneWidget);
    });

    testWidgets('a failed pull-to-refresh keeps the list', (tester) async {
      final s = _Setup(teens: [_dana]);
      s.taskRepository.tasks = [fakeTask(teenId: 'teen1')];
      await pumpApp(tester, overrides: s.overrides);
      expect(find.text('1 active'), findsOneWidget);

      s.taskRepository.error = const ApiException(code: 'network_error');
      s.family.error = const ApiException(code: 'network_error');
      await _pullToRefresh(tester);

      expect(find.text('Dana'), findsOneWidget);
      expect(find.text('1 active'), findsOneWidget);
      expect(find.text('No connection. Check your network.'), findsNothing);
    });

    testWidgets('pull-to-refresh shows new data', (tester) async {
      final s = _Setup(teens: [_dana]);
      await pumpApp(tester, overrides: s.overrides);
      s.taskRepository.tasks = [
        fakeTask(teenId: 'teen1', state: TaskState.submitted),
      ];
      await _pullToRefresh(tester);
      expect(find.text('1 to check'), findsOneWidget);
    });
  });

  group('nobody linked yet', () {
    testWidgets('the code is the page', (tester) async {
      final s = _Setup();
      await pumpApp(tester, overrides: s.overrides);

      expect(find.text('Connect your teen'), findsOneWidget);
      expect(find.text('SXVPUR'), findsOneWidget);
      expect(find.text('Send code'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('My teens'), findsNothing);
    });

    testWidgets('a teen who joins meanwhile shows up on resume', (
      tester,
    ) async {
      final s = _Setup();
      await pumpApp(tester, overrides: s.overrides);
      expect(s.family.calls, 1);

      s.family.members_ = [teenMember('teen1', 'Dana')];
      _background(tester);
      await tester.pump();
      expect(s.family.calls, 1, reason: 'going to the background: no fetch');

      await _foreground(tester);
      expect(s.family.calls, 2);
      expect(find.text('Dana'), findsOneWidget);
      expect(find.text('Connect your teen'), findsNothing);
    });
  });

  group('add teen sheet', () {
    testWidgets('the code is off the page until Add is tapped', (tester) async {
      final s = _Setup(teens: [_dana]);
      await pumpApp(tester, overrides: s.overrides);
      expect(find.text('SXVPUR'), findsNothing);

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Add a teen'), findsOneWidget);
      expect(find.text('SXVPUR'), findsOneWidget);
      expect(find.text('Send code'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('Copy puts the code on the clipboard', (tester) async {
      final s = _Setup(teens: [_dana]);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpApp(tester, overrides: s.overrides);
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(copied, 'SXVPUR');
      expect(find.text('Code copied'), findsOneWidget);
    });
  });

  group('refetching without push', () {
    testWidgets('on resume: one refetch of family and both lists', (
      tester,
    ) async {
      final s = _Setup(teens: [_dana]);
      await pumpApp(tester, overrides: s.overrides);
      expect((s.family.calls, s.taskRepository.calls), (1, 2));

      s.taskRepository.tasks = [
        fakeTask(teenId: 'teen1', state: TaskState.submitted),
      ];
      _background(tester);
      await tester.pump();
      expect((s.family.calls, s.taskRepository.calls), (1, 2));

      await _foreground(tester);
      expect((s.family.calls, s.taskRepository.calls), (2, 4));
      expect(find.text('1 to check'), findsOneWidget);
    });

    testWidgets('selecting the tab refetches', (tester) async {
      final s = _Setup(teens: [_dana]);
      await pumpApp(tester, overrides: s.overrides);
      expect(s.taskRepository.calls, 2);

      await tester.tap(find.text('To check'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect((s.family.calls, s.taskRepository.calls), (2, 4));
    });

    testWidgets('a hidden tab does not refetch on resume', (tester) async {
      final s = _Setup(teens: [_dana]);
      await pumpApp(tester, overrides: s.overrides);
      await tester.tap(find.text('To check'));
      await tester.pumpAndSettle();
      final before = (s.family.calls, s.taskRepository.calls);

      _background(tester);
      await tester.pump();
      await _foreground(tester);
      expect((s.family.calls, s.taskRepository.calls), before);
    });
  });

  group('navigation bar', () {
    testWidgets('Home and To check only', (tester) async {
      final s = _Setup(teens: [_dana]);
      await pumpApp(tester, overrides: s.overrides);
      expect(find.byType(NavigationDestination), findsNWidgets(2));
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('To check'), findsOneWidget);
      expect(find.text('Activity'), findsNothing);
    });

    testWidgets('To check carries a count badge, hidden at 0', (tester) async {
      final semantics = tester.ensureSemantics();
      final s = _Setup(teens: [_dana]);
      await pumpApp(tester, overrides: s.overrides);
      expect(find.byType(Badge), findsNothing);

      s.taskRepository.tasks = [
        fakeTask(id: '1', teenId: 'teen1', state: TaskState.submitted),
        fakeTask(id: '2', teenId: 'teen1', state: TaskState.submitted),
      ];
      await _pullToRefresh(tester);
      expect(find.byType(Badge), findsOneWidget);
      expect(
        find.descendant(of: find.byType(Badge), matching: find.text('2')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('2 waiting')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('more than 9 shows 9+', (tester) async {
      final s = _Setup(teens: [_dana]);
      s.taskRepository.tasks = [
        for (var i = 0; i < 12; i++)
          fakeTask(id: 'x$i', teenId: 'teen1', state: TaskState.submitted),
      ];
      await pumpApp(tester, overrides: s.overrides);
      expect(
        find.descendant(of: find.byType(Badge), matching: find.text('9+')),
        findsOneWidget,
      );
    });
  });
}
