import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/features/parent/application/review_providers.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

import '../../helpers/fake_tasks.dart';

void main() {
  test('the queue is oldest submission first, unknown times last', () {
    DateTime d(int h) => DateTime.utc(2026, 11, 7, h);
    final queue = reviewQueue([
      fakeTask(id: 'c', state: TaskState.submitted, submittedAt: d(12)),
      fakeTask(id: 'none', state: TaskState.submitted),
      fakeTask(id: 'a', state: TaskState.submitted, submittedAt: d(8)),
      fakeTask(id: 'b', state: TaskState.submitted, submittedAt: d(9)),
    ]);
    expect(queue.map((t) => t.id), ['a', 'b', 'c', 'none']);
  });

  test('equal times are ordered by id, so the list never jumps', () {
    final t = DateTime.utc(2026, 11, 7, 8);
    final queue = reviewQueue([
      fakeTask(id: 'z', submittedAt: t),
      fakeTask(id: 'a', submittedAt: t),
    ]);
    expect(queue.map((x) => x.id), ['a', 'z']);
  });

  test('an empty queue is empty', () {
    expect(reviewQueue(const []), isEmpty);
  });
}
