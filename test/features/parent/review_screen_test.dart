import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/features/tasks/data/proof.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

import '../../helpers/fake_tasks.dart';
import '../../helpers/parent_harness.dart';
import '../../helpers/pump_app.dart';

const _dana = (id: 'teen1', name: 'Dana');
const _aibek = (id: 'teen2', name: 'Aibek');

DateTime _at(int hour) => DateTime.utc(2026, 11, 7, hour);

Proof _textProof(String text, {int attempt = 1}) =>
    Proof(attemptNo: attempt, text: text, createdAt: _at(10));

Proof _imageProof({int attempt = 1}) => Proof(
  attemptNo: attempt,
  imageUrl: 'https://s3.test/p.jpg?X-Amz-Signature=abc',
  createdAt: _at(10),
);

ParentHarness _harness() {
  final h = ParentHarness(teens: [_dana, _aibek]);
  h.tasks.tasks = [
    fakeTask(
      id: 'late',
      teenId: 'teen2',
      title: 'Math homework',
      state: TaskState.submitted,
      submittedAt: _at(11),
    ),
    fakeTask(
      id: 'early',
      teenId: 'teen1',
      title: 'Wash dishes',
      state: TaskState.submitted,
      submittedAt: _at(8),
    ),
  ];
  h.tasks.proofsById['early'] = [_textProof('All clean, sent from the sink')];
  h.tasks.proofsById['late'] = [_imageProof()];
  return h;
}

Future<void> _openToCheck(WidgetTester tester) async {
  await tester.tap(find.text('To check').first);
  await tester.pumpAndSettle();
}

Future<void> _openReview(WidgetTester tester, String title) async {
  await _openToCheck(tester);
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

void _tall(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(400, 1100)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('the To check list', () {
    testWidgets('oldest submission first, with the teen\'s name', (
      tester,
    ) async {
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      await _openToCheck(tester);

      expect(find.text('Wash dishes'), findsOneWidget);
      expect(find.text('Math homework'), findsOneWidget);
      expect(find.text('Dana'), findsOneWidget);
      expect(find.text('Aibek'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Wash dishes')).dy,
        lessThan(tester.getTopLeft(find.text('Math homework')).dy),
      );
    });

    testWidgets('nothing to check says so', (tester) async {
      final h = ParentHarness(teens: [_dana]);
      await pumpApp(tester, overrides: h.overrides);
      await _openToCheck(tester);
      expect(find.text('Nothing to check. Nice!'), findsOneWidget);
    });

    testWidgets('a failed load shows a message and retries', (tester) async {
      final h = ParentHarness(teens: [_dana]);
      await pumpApp(tester, overrides: h.overrides);
      h.tasks.error = const ApiException(code: 'network_error');
      await _openToCheck(tester); // selecting the tab refetches
      h.tasks.error = null;
      h.tasks.tasks = [fakeTask(title: 'Back', state: TaskState.submitted)];
      await tester.pumpAndSettle();
      await tester.fling(
        find.byType(ListView).first,
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('selecting the tab refetches the list', (tester) async {
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      final before = h.tasks.callsFor(TaskState.submitted);
      await _openToCheck(tester);
      expect(h.tasks.callsFor(TaskState.submitted), before + 1);
    });

    testWidgets('a row opens the review and back returns', (tester) async {
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      await _openReview(tester, 'Wash dishes');
      expect(routerOf(tester).state.matchedLocation, '/parent/review/early');
      expect(find.byType(NavigationBar), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(routerOf(tester).state.matchedLocation, '/parent/review');
    });
  });

  group('the review screen', () {
    testWidgets('shows the task, the teen and a text proof', (tester) async {
      _tall(tester);
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      await _openReview(tester, 'Wash dishes');

      expect(find.text('Wash dishes'), findsOneWidget);
      expect(find.text('Dana'), findsOneWidget);
      expect(find.text('All clean, sent from the sink'), findsOneWidget);
      expect(find.textContaining('Attempt 1'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Ask to redo'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('shows the latest attempt', (tester) async {
      _tall(tester);
      final h = _harness();
      h.tasks.proofsById['early'] = [
        _textProof('first try', attempt: 1),
        _textProof('second try', attempt: 2),
      ];
      await pumpApp(tester, overrides: h.overrides);
      await _openReview(tester, 'Wash dishes');
      expect(find.text('second try'), findsOneWidget);
      expect(find.text('first try'), findsNothing);
      expect(find.textContaining('Attempt 2'), findsOneWidget);
    });

    testWidgets('no proof is said plainly', (tester) async {
      _tall(tester);
      final h = _harness();
      h.tasks.proofsById['early'] = [];
      await pumpApp(tester, overrides: h.overrides);
      await _openReview(tester, 'Wash dishes');
      expect(find.text('No proof was attached.'), findsOneWidget);
    });

    testWidgets('a task that is no longer submitted offers no decisions', (
      tester,
    ) async {
      _tall(tester);
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      await _openToCheck(tester);
      // It was approved elsewhere after the list loaded.
      final i = h.tasks.tasks.indexWhere((t) => t.id == 'early');
      h.tasks.tasks[i] = h.tasks.tasks[i].copyWith(state: TaskState.approved);
      await tester.tap(find.text('Wash dishes'));
      await tester.pumpAndSettle();
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
    });

    group('Approve', () {
      testWidgets('calls approve once, goes back and refreshes', (
        tester,
      ) async {
        _tall(tester);
        final h = _harness();
        await pumpApp(tester, overrides: h.overrides);
        await _openReview(tester, 'Wash dishes');
        final before = h.tasks.callsFor(TaskState.submitted);

        await tester.tap(find.text('Approve'));
        await tester.pumpAndSettle();

        expect(h.tasks.decisions.map((d) => '${d.action}:${d.id}'), [
          'approve:early',
        ]);
        expect(routerOf(tester).state.matchedLocation, '/parent/review');
        expect(h.tasks.callsFor(TaskState.submitted), greaterThan(before));
        expect(find.text('Wash dishes'), findsNothing, reason: 'no longer due');
      });

      testWidgets('a double tap sends once', (tester) async {
        _tall(tester);
        final h = _harness();
        final gate = Completer<void>();
        h.tasks.onDecision = (_, _) => gate.future;
        await pumpApp(tester, overrides: h.overrides);
        await _openReview(tester, 'Wash dishes');

        await tester.tap(find.text('Approve'));
        await tester.pump();
        await tester.tap(find.byType(FilledButton), warnIfMissed: false);
        await tester.pump();
        expect(h.tasks.decisions, hasLength(1));

        gate.complete();
        await tester.pumpAndSettle();
        expect(h.tasks.decisions, hasLength(1));
      });
    });

    group('Ask to redo', () {
      testWidgets('sends the note', (tester) async {
        _tall(tester);
        final h = _harness();
        await pumpApp(tester, overrides: h.overrides);
        await _openReview(tester, 'Wash dishes');

        await tester.tap(find.text('Ask to redo'));
        await tester.pumpAndSettle();
        expect(find.textContaining('goes back to Dana'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'The pans too');
        await tester.tap(find.text('Send'));
        await tester.pumpAndSettle();

        final d = h.tasks.decisions.single;
        expect(d.action, 'redo');
        expect(d.note, 'The pans too');
        expect(d.deadline, isNull, reason: 'the current deadline is kept');
        expect(routerOf(tester).state.matchedLocation, '/parent/review');
      });

      testWidgets('Cancel sends nothing', (tester) async {
        _tall(tester);
        final h = _harness();
        await pumpApp(tester, overrides: h.overrides);
        await _openReview(tester, 'Wash dishes');
        await tester.tap(find.text('Ask to redo'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(h.tasks.decisions, isEmpty);
        expect(routerOf(tester).state.matchedLocation, '/parent/review/early');
      });
    });

    group('Reject', () {
      testWidgets('says it is final, then sends the note', (tester) async {
        _tall(tester);
        final h = _harness();
        await pumpApp(tester, overrides: h.overrides);
        await _openReview(tester, 'Wash dishes');

        await tester.tap(find.text('Reject'));
        await tester.pumpAndSettle();
        expect(find.text('Reject this task?'), findsOneWidget);
        expect(find.textContaining('This is final.'), findsOneWidget);
        expect(h.tasks.decisions, isEmpty, reason: 'not yet');

        await tester.enterText(find.byType(TextField), 'Not what I asked');
        await tester.tap(find.widgetWithText(FilledButton, 'Reject'));
        await tester.pumpAndSettle();

        final d = h.tasks.decisions.single;
        expect(d.action, 'reject');
        expect(d.note, 'Not what I asked');
      });

      testWidgets('Cancel in the confirmation rejects nothing', (tester) async {
        _tall(tester);
        final h = _harness();
        await pumpApp(tester, overrides: h.overrides);
        await _openReview(tester, 'Wash dishes');
        await tester.tap(find.text('Reject'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(h.tasks.decisions, isEmpty);
      });
    });

    group('when the task changed under us', () {
      for (final code in ['invalid_transition', 'concurrent_modification']) {
        testWidgets('$code says so and shows the latest', (tester) async {
          _tall(tester);
          final h = _harness();
          h.tasks.onDecision = (_, id) async {
            // Someone else got there first.
            final i = h.tasks.tasks.indexWhere((t) => t.id == id);
            h.tasks.tasks[i] = h.tasks.tasks[i].copyWith(
              state: TaskState.approved,
            );
            throw ApiException(code: code, statusCode: 409);
          };
          await pumpApp(tester, overrides: h.overrides);
          await _openReview(tester, 'Wash dishes');
          final gets = h.tasks.getCalls;

          await tester.tap(find.text('Approve'));
          await tester.pumpAndSettle();

          expect(
            find.text('This task just changed. Here is the latest.'),
            findsOneWidget,
          );
          expect(h.tasks.getCalls, gets + 1, reason: 'reloaded');
          expect(
            routerOf(tester).state.matchedLocation,
            '/parent/review/early',
          );
          expect(find.text('Approved'), findsOneWidget);
          expect(
            find.text('Approve'),
            findsNothing,
            reason: 'nothing to decide',
          );
        });
      }

      testWidgets('any other error is shown plainly and the task stays', (
        tester,
      ) async {
        _tall(tester);
        final h = _harness();
        h.tasks.onDecision = (_, _) async =>
            throw const ApiException(code: 'network_error');
        await pumpApp(tester, overrides: h.overrides);
        await _openReview(tester, 'Wash dishes');
        await tester.tap(find.text('Approve'));
        await tester.pumpAndSettle();

        expect(find.text('No connection. Check your network.'), findsOneWidget);
        expect(find.text('Approve'), findsOneWidget);
        expect(routerOf(tester).state.matchedLocation, '/parent/review/early');
      });
    });
  });

  group('photo proofs', () {
    // The test HTTP layer answers every image request with an error, which is
    // what an expired presigned URL looks like.
    testWidgets('a failed photo refetches the proofs once, then offers retry', (
      tester,
    ) async {
      _tall(tester);
      final h = _harness();
      await pumpApp(tester, overrides: h.overrides);
      await _openReview(tester, 'Math homework');
      await tester.pumpAndSettle();

      expect(h.tasks.proofCalls, 2, reason: 'first load + exactly one refetch');
      expect(find.text('Could not load the photo.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(h.tasks.proofCalls, 4, reason: 'a manual try is a fresh pair');
    });
  });
}
