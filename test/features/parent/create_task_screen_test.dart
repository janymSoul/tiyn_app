import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/features/tasks/data/task.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

import '../../helpers/fake_tasks.dart';
import '../../helpers/parent_harness.dart';
import '../../helpers/pump_app.dart';

const _dana = (id: 'teen1', name: 'Dana');

Finder _field(String label) => find.widgetWithText(TextField, label);

void _tall(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(400, 1100)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<ParentHarness> _openForm(WidgetTester tester) async {
  _tall(tester);
  final h = ParentHarness(teens: [_dana]);
  await pumpApp(tester, overrides: h.overrides);
  await tester.tap(find.text('New task'));
  await tester.pumpAndSettle();
  return h;
}

Future<void> _fill(
  WidgetTester tester, {
  String title = 'Wash dishes',
  String reward = '1 500',
}) async {
  await tester.enterText(_field('Title'), title);
  await tester.enterText(_field('Reward (₸)'), reward);
  await tester.pump();
}

Future<void> _tapAdd(WidgetTester tester) async {
  await tester.tap(find.text('Add task'));
  await tester.pumpAndSettle();
}

String _key(ParentHarness h, int i) => h.tasks.created[i].key.value;

void main() {
  group('opening', () {
    testWidgets('the New task button on a teen row opens the form', (
      tester,
    ) async {
      await _openForm(tester);
      expect(routerOf(tester).state.matchedLocation, '/parent/new');
      expect(find.text('New task'), findsOneWidget, reason: 'the title');
      expect(find.text('For Dana'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing, reason: 'full screen');
      expect(find.byTooltip('Close'), findsOneWidget);
    });

    testWidgets('the + on teen detail opens a task or a milestone form', (
      tester,
    ) async {
      _tall(tester);
      final h = ParentHarness(teens: [_dana]);
      await pumpApp(tester, overrides: h.overrides);
      await tester.tap(find.text('Dana'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('New task'));
      await tester.pumpAndSettle();
      expect(find.text('Add task'), findsOneWidget);
      expect(find.text('Add a penalty if it\'s missed'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Milestones (0)'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('New milestone'));
      await tester.pumpAndSettle();
      expect(find.text('New milestone'), findsOneWidget);
      expect(find.text('Add milestone'), findsOneWidget);
      expect(
        find.text('Add a penalty if it\'s missed'),
        findsNothing,
        reason: 'a milestone has no penalty',
      );
    });

    testWidgets('Close goes back without sending anything', (tester) async {
      final h = await _openForm(tester);
      await _fill(tester);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(routerOf(tester).state.matchedLocation, '/parent/home');
      expect(h.tasks.created, isEmpty);
    });

    testWidgets('the deadline defaults to tomorrow 18:00', (tester) async {
      await _openForm(tester);
      expect(find.text('18:00'), findsOneWidget);
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final expected = MaterialLocalizations.of(
        tester.element(find.byType(Scaffold).last),
      ).formatMediumDate(tomorrow);
      expect(find.text(expected), findsOneWidget);
    });

    testWidgets('the penalty field is hidden until asked for', (tester) async {
      await _openForm(tester);
      expect(_field('Penalty (₸)'), findsNothing);
      await tester.tap(find.text('Add a penalty if it\'s missed'));
      await tester.pumpAndSettle();
      expect(_field('Penalty (₸)'), findsOneWidget);
    });
  });

  group('validation', () {
    testWidgets('errors appear under the fields and nothing is sent', (
      tester,
    ) async {
      final h = await _openForm(tester);
      await _tapAdd(tester);
      expect(find.text('Enter a title.'), findsOneWidget);
      expect(find.text('Enter an amount, like 1 500.'), findsOneWidget);
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason: 'inline, no dialog',
      );
      expect(h.tasks.created, isEmpty);
    });

    testWidgets('a reward over the maximum is explained', (tester) async {
      final h = await _openForm(tester);
      await _fill(tester, reward: '100 001');
      await _tapAdd(tester);
      expect(
        find.textContaining('The reward must be more than 0 and at most'),
        findsOneWidget,
      );
      expect(h.tasks.created, isEmpty);
    });

    testWidgets('errors clear as the field is fixed', (tester) async {
      await _openForm(tester);
      await _tapAdd(tester);
      await tester.enterText(_field('Title'), 'Wash dishes');
      await tester.pump();
      expect(find.text('Enter a title.'), findsNothing);
    });

    testWidgets('the amount field only takes digits, spaces, comma, dot', (
      tester,
    ) async {
      await _openForm(tester);
      await tester.enterText(_field('Reward (₸)'), 'a1b 5-0,5');
      await tester.pump();
      expect(
        tester.widget<TextField>(_field('Reward (₸)')).controller!.text,
        '1 50,5',
      );
    });
  });

  group('sending', () {
    testWidgets('one tap sends exactly one request with the key', (
      tester,
    ) async {
      final h = await _openForm(tester);
      await _fill(tester);
      await _tapAdd(tester);

      expect(h.tasks.created, hasLength(1));
      final sent = h.tasks.created.single;
      expect(sent.key.value, isNotEmpty);
      expect(sent.task.teenId, 'teen1');
      expect(sent.task.kind, TaskKind.task);
      expect(sent.task.title, 'Wash dishes');
      expect(sent.task.reward, const Money.kzt(150000));
      expect(sent.task.penalty, Money.zero);
      expect(routerOf(tester).state.matchedLocation, '/parent/home');
    });

    testWidgets('the penalty is sent when entered', (tester) async {
      final h = await _openForm(tester);
      await _fill(tester);
      await tester.tap(find.text('Add a penalty if it\'s missed'));
      await tester.pumpAndSettle();
      await tester.enterText(_field('Penalty (₸)'), '300');
      await _tapAdd(tester);
      expect(h.tasks.created.single.task.penalty, const Money.kzt(30000));
    });

    testWidgets('a double tap while sending sends once', (tester) async {
      final h = await _openForm(tester);
      final gate = Completer<Task>();
      h.tasks.onCreate = (_, _) => gate.future;
      await _fill(tester);

      await tester.tap(find.text('Add task'));
      await tester.pump();
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();
      expect(h.tasks.created, hasLength(1));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      gate.complete(fakeTask());
      await tester.pumpAndSettle();
      expect(h.tasks.created, hasLength(1));
    });

    testWidgets('a created task refreshes the open-work list behind it', (
      tester,
    ) async {
      final h = await _openForm(tester);
      final before = h.tasks.callsFor(TaskState.assigned);
      await _fill(tester);
      await _tapAdd(tester);
      expect(h.tasks.callsFor(TaskState.assigned), before + 1);
    });
  });

  group('server rejects (4xx): nothing was created', () {
    testWidgets('invalid_reward lands under the reward field', (tester) async {
      final h = await _openForm(tester);
      h.tasks.onCreate = (_, _) async =>
          throw const ApiException(code: 'invalid_reward', statusCode: 422);
      await _fill(tester);
      await _tapAdd(tester);

      expect(
        find.text('The server did not accept this reward.'),
        findsOneWidget,
      );
      expect(routerOf(tester).state.matchedLocation, '/parent/new');
      expect(tester.widget<TextField>(_field('Title')).enabled, isTrue);
    });

    testWidgets('invalid_milestone is a message for the whole form', (
      tester,
    ) async {
      final h = await _openForm(tester);
      h.tasks.onCreate = (_, _) async =>
          throw const ApiException(code: 'invalid_milestone', statusCode: 422);
      await _fill(tester);
      await _tapAdd(tester);
      expect(find.text('That milestone is no longer open.'), findsOneWidget);
    });

    testWidgets('resending unchanged keeps the key; an edit makes a new one', (
      tester,
    ) async {
      final h = await _openForm(tester);
      var fail = true;
      h.tasks.onCreate = (task, _) async {
        if (fail) {
          throw const ApiException(code: 'invalid_reward', statusCode: 422);
        }
        return fakeTask(title: task.title);
      };
      await _fill(tester);
      await _tapAdd(tester);
      await _tapAdd(tester);
      expect(_key(h, 1), _key(h, 0), reason: 'same payload, same key');

      await tester.enterText(_field('Reward (₸)'), '2 000');
      await tester.pump();
      fail = false;
      await _tapAdd(tester);
      expect(h.tasks.created, hasLength(3));
      expect(_key(h, 2), isNot(_key(h, 0)), reason: 'edited, new key');
      expect(h.tasks.created[2].task.reward, const Money.kzt(200000));
    });
  });

  group('server did not answer: the task may exist', () {
    Future<ParentHarness> timedOut(WidgetTester tester) async {
      final h = await _openForm(tester);
      var fail = true;
      h.tasks.onCreate = (task, _) async {
        if (fail) {
          fail = false;
          throw const ApiException(code: 'timeout');
        }
        return fakeTask(title: task.title);
      };
      await _fill(tester);
      await _tapAdd(tester);
      return h;
    }

    testWidgets('the form locks and the main action is Try again', (
      tester,
    ) async {
      await timedOut(tester);
      expect(routerOf(tester).state.matchedLocation, '/parent/new');
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Add task'), findsNothing);
      expect(find.textContaining('it will not be added twice'), findsOneWidget);
      expect(tester.widget<TextField>(_field('Title')).enabled, isFalse);
      expect(tester.widget<TextField>(_field('Reward (₸)')).enabled, isFalse);
      expect(find.text('Edit details'), findsOneWidget);
    });

    testWidgets('Try again resends the same key and payload', (tester) async {
      final h = await timedOut(tester);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(h.tasks.created, hasLength(2));
      expect(_key(h, 1), _key(h, 0));
      expect(h.tasks.created[1].task, h.tasks.created[0].task);
      expect(routerOf(tester).state.matchedLocation, '/parent/home');
    });

    testWidgets('Edit details needs a confirmation first', (tester) async {
      final h = await timedOut(tester);
      await tester.tap(find.text('Edit details'));
      await tester.pumpAndSettle();
      expect(find.text('Change the details?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(_field('Title')).enabled, isFalse);
      expect(h.tasks.created, hasLength(1));
    });

    testWidgets('after confirming, editing sends under a new key', (
      tester,
    ) async {
      final h = await timedOut(tester);
      await tester.tap(find.text('Edit details'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change anyway'));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(_field('Title')).enabled, isTrue);
      expect(find.text('Add task'), findsOneWidget);
      await tester.enterText(_field('Title'), 'Wash the pans');
      await tester.pump();
      await _tapAdd(tester);

      expect(h.tasks.created, hasLength(2));
      expect(_key(h, 1), isNot(_key(h, 0)));
      expect(h.tasks.created[1].task.title, 'Wash the pans');
    });

    testWidgets('a 500 is treated the same way', (tester) async {
      final h = await _openForm(tester);
      h.tasks.onCreate = (_, _) async =>
          throw const ApiException(code: 'internal_error', statusCode: 500);
      await _fill(tester);
      await _tapAdd(tester);
      expect(find.text('Try again'), findsOneWidget);
      expect(tester.widget<TextField>(_field('Title')).enabled, isFalse);
    });
  });
}
