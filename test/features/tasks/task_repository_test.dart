import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/network/api_client.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/idempotency_key.dart';
import 'package:tiyn_app/features/tasks/data/new_task.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';
import 'package:tiyn_app/features/tasks/data/task_repository.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/fakes.dart';

Map<String, Object?> _taskJson({String id = 't1', String state = 'ASSIGNED'}) =>
    {
      'id': id,
      'teenId': 'teen',
      'parentId': 'parent',
      'kind': 'TASK',
      'title': 'Wash dishes',
      'rewardAmount': 150000,
      'penaltyAmount': 0,
      'currency': 'KZT',
      'state': state,
      'deadlineAt': '2026-11-03T18:00:00Z',
    };

({TaskRepository repository, FakeAdapter adapter}) _setup(FakeHandler handler) {
  final adapter = FakeAdapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = adapter;
  final api = ApiClient(
    baseUrl: Uri.parse('https://api.test'),
    tokens: FakeTokenStorage('token'),
    onUnauthorized: () {},
    dio: dio,
  );
  return (repository: TaskRepository(api), adapter: adapter);
}

({TaskRepository repository, FakeAdapter adapter}) _ok([Object? body]) =>
    _setup((_, _) async => jsonBody(body ?? _taskJson()));

final _draft = NewTask(
  teenId: 'teen',
  title: 'Wash dishes',
  description: 'All of them',
  reward: const Money.kzt(150000),
  penalty: const Money.kzt(10000),
  deadlineAt: DateTime.utc(2026, 11, 3, 18),
);

Object? _json(String body) => jsonDecode(body);

void main() {
  group('list', () {
    test('no filters: GET /tasks without a query', () async {
      final s = _ok([_taskJson(id: 'a'), _taskJson(id: 'b')]);
      final tasks = await s.repository.list();
      expect(tasks.map((t) => t.id), ['a', 'b']);
      final r = s.adapter.requests.single;
      expect(r.method, 'GET');
      expect(r.path, '/tasks');
      expect(r.queryParameters, {'limit': 100});
    });

    test('state filter is sent as the wire value', () async {
      final s = _ok([]);
      await s.repository.list(state: TaskState.submitted);
      expect(s.adapter.requests.single.queryParameters, {
        'state': 'SUBMITTED',
        'limit': 100,
      });
    });

    test('teenId filter', () async {
      final s = _ok([]);
      await s.repository.list(teenId: 'teen-1');
      expect(s.adapter.requests.single.queryParameters, {
        'teenId': 'teen-1',
        'limit': 100,
      });
    });

    test('both filters', () async {
      final s = _ok([]);
      await s.repository.list(teenId: 'teen-1', state: TaskState.assigned);
      expect(s.adapter.requests.single.queryParameters, {
        'teenId': 'teen-1',
        'state': 'ASSIGNED',
        'limit': 100,
      });
    });

    test('an unknown state in the response is invalid_response', () async {
      final s = _ok([_taskJson(state: 'PAUSED')]);
      await expectLater(
        s.repository.list(),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'invalid_response'),
        ),
      );
    });

    test('envelope shape: items are parsed', () async {
      final s = _ok({
        'items': [_taskJson(id: 'a'), _taskJson(id: 'b')],
      });
      final tasks = await s.repository.list();
      expect(tasks.map((t) => t.id), ['a', 'b']);
      expect(s.adapter.requests, hasLength(1));
    });

    test('envelope with nextCursor: follows to the last page', () async {
      final s = _setup((o, _) async {
        final first = o.queryParameters['cursor'] == null;
        return jsonBody(
          first
              ? {
                  'items': [_taskJson(id: 'a')],
                  'nextCursor': 'c1',
                }
              : {
                  'items': [_taskJson(id: 'b')],
                },
        );
      });
      final tasks = await s.repository.list(state: TaskState.assigned);
      expect(tasks.map((t) => t.id), ['a', 'b']);
      expect(s.adapter.requests.last.queryParameters, {
        'state': 'ASSIGNED',
        'limit': 100,
        'cursor': 'c1',
      });
    });

    test('a non-list body is invalid_response', () async {
      final s = _ok(_taskJson());
      await expectLater(
        s.repository.list(),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'invalid_response'),
        ),
      );
    });
  });

  test('get: GET /tasks/{id}', () async {
    final s = _ok();
    final task = await s.repository.get('t1');
    expect(task.id, 't1');
    expect(s.adapter.requests.single.method, 'GET');
    expect(s.adapter.requests.single.path, '/tasks/t1');
  });

  group('create', () {
    test('sends the body and the Idempotency-Key header', () async {
      final s = _ok();
      const key = IdempotencyKey('key-1');
      await s.repository.create(_draft, key: key);
      final r = s.adapter.requests.single;
      expect(r.method, 'POST');
      expect(r.path, '/tasks');
      expect(r.headers['Idempotency-Key'], 'key-1');
      expect(r.headers['Authorization'], 'Bearer token');
    });

    test('the body is in minor units, UTC, with KZT', () async {
      late String body;
      final s = _setup((_, b) async {
        body = b;
        return jsonBody(_taskJson());
      });
      await s.repository.create(_draft, key: IdempotencyKey.generate());
      expect(_json(body), {
        'teenId': 'teen',
        'kind': 'TASK',
        'title': 'Wash dishes',
        'description': 'All of them',
        'rewardAmount': 150000,
        'penaltyAmount': 10000,
        'currency': 'KZT',
        'deadlineAt': '2026-11-03T18:00:00.000Z',
      });
    });

    test(
      'a milestone child carries milestoneId; a milestone has kind',
      () async {
        late String body;
        final s = _setup((_, b) async {
          body = b;
          return jsonBody(_taskJson());
        });
        await s.repository.create(
          NewTask(
            teenId: 'teen',
            kind: TaskKind.milestone,
            title: 'Term',
            reward: const Money.kzt(500000),
            deadlineAt: DateTime.utc(2026, 12),
            milestoneId: null,
          ),
          key: IdempotencyKey.generate(),
        );
        expect((_json(body)! as Map)['kind'], 'MILESTONE');
        expect((_json(body)! as Map).containsKey('milestoneId'), isFalse);

        await s.repository.create(
          NewTask(
            teenId: 'teen',
            title: 'Step',
            reward: const Money.kzt(100),
            deadlineAt: DateTime.utc(2026, 12),
            milestoneId: 'ms-1',
          ),
          key: IdempotencyKey.generate(),
        );
        expect((_json(body)! as Map)['milestoneId'], 'ms-1');
      },
    );

    test('a local deadline is converted to UTC on the wire', () async {
      late String body;
      final s = _setup((_, b) async {
        body = b;
        return jsonBody(_taskJson());
      });
      final local = DateTime.utc(2026, 11, 3, 18).toLocal();
      await s.repository.create(
        NewTask(
          teenId: 'teen',
          title: 'x',
          reward: const Money.kzt(100),
          deadlineAt: local,
        ),
        key: IdempotencyKey.generate(),
      );
      expect((_json(body)! as Map)['deadlineAt'], '2026-11-03T18:00:00.000Z');
    });

    test(
      'a retry of the same attempt reuses the key; a new attempt does not',
      () async {
        final s = _ok();
        const first = IdempotencyKey('attempt-1');
        await s.repository.create(_draft, key: first);
        await s.repository.create(_draft, key: first);
        await s.repository.create(
          _draft,
          key: const IdempotencyKey('attempt-2'),
        );
        final keys = s.adapter.requests
            .map((r) => r.headers['Idempotency-Key'])
            .toList();
        expect(keys, ['attempt-1', 'attempt-1', 'attempt-2']);
      },
    );

    test('a 422 surfaces its code', () async {
      final s = _setup(
        (_, _) async => jsonBody({'error': 'invalid_reward'}, status: 422),
      );
      await expectLater(
        s.repository.create(_draft, key: IdempotencyKey.generate()),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'invalid_reward')
              .having((e) => e.statusCode, 'status', 422),
        ),
      );
    });
  });

  group('decisions', () {
    test('approve and cancel: POST, no body, no key', () async {
      final s = _ok();
      await s.repository.approve('t1');
      await s.repository.cancel('t1');
      expect(s.adapter.requests.map((r) => '${r.method} ${r.path}'), [
        'POST /tasks/t1/approve',
        'POST /tasks/t1/cancel',
      ]);
      for (final r in s.adapter.requests) {
        expect(r.headers.containsKey('Idempotency-Key'), isFalse);
      }
    });

    test('reject with a note sends it trimmed; blank sends no body', () async {
      final bodies = <String>[];
      final s = _setup((_, b) async {
        bodies.add(b);
        return jsonBody(_taskJson());
      });
      await s.repository.reject('t1', note: '  Not done  ');
      await s.repository.reject('t1', note: '   ');
      await s.repository.reject('t1');
      expect(
        s.adapter.requests.map((r) => r.path),
        everyElement('/tasks/t1/reject'),
      );
      expect(_json(bodies[0]), {'note': 'Not done'});
      expect(bodies[1], isEmpty);
      expect(bodies[2], isEmpty);
    });

    test('request-redo sends the note and a UTC deadline', () async {
      late String body;
      final s = _setup((_, b) async {
        body = b;
        return jsonBody(_taskJson());
      });
      await s.repository.requestRedo(
        't1',
        note: 'Again',
        deadlineAt: DateTime.utc(2026, 11, 5, 9),
      );
      expect(s.adapter.requests.single.path, '/tasks/t1/request-redo');
      expect(_json(body), {
        'note': 'Again',
        'deadlineAt': '2026-11-05T09:00:00.000Z',
      });
    });

    test('request-redo without options sends an empty object', () async {
      late String body;
      final s = _setup((_, b) async {
        body = b;
        return jsonBody(_taskJson());
      });
      await s.repository.requestRedo('t1');
      expect(_json(body), <String, Object?>{});
    });

    test('a 409 invalid_transition surfaces its code', () async {
      final s = _setup(
        (_, _) async => jsonBody({'error': 'invalid_transition'}, status: 409),
      );
      await expectLater(
        s.repository.approve('t1'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'invalid_transition',
          ),
        ),
      );
    });
  });

  group('proofs', () {
    test('GET /tasks/{id}/proofs decodes the list', () async {
      final s = _ok([
        {
          'attemptNo': 1,
          'imageUrl': 'https://s3.test/p',
          'createdAt': '2026-11-02T10:30:00Z',
        },
        {'attemptNo': 2, 'text': 'Done', 'createdAt': '2026-11-02T11:00:00Z'},
      ]);
      final proofs = await s.repository.proofs('t1');
      expect(proofs.map((p) => p.attemptNo), [1, 2]);
      expect(proofs[0].imageUrl, 'https://s3.test/p');
      expect(proofs[1].text, 'Done');
      expect(s.adapter.requests.single.path, '/tasks/t1/proofs');
    });
  });

  group('submit', () {
    test('text: JSON body and the key', () async {
      late String body;
      final s = _setup((_, b) async {
        body = b;
        return jsonBody(_taskJson(state: 'SUBMITTED'));
      });
      final task = await s.repository.submitText(
        't1',
        'All done',
        key: const IdempotencyKey('k-text'),
      );
      expect(task.state, TaskState.submitted);
      final r = s.adapter.requests.single;
      expect(r.method, 'POST');
      expect(r.path, '/tasks/t1/submit');
      expect(r.headers['Idempotency-Key'], 'k-text');
      expect(_json(body), {'text': 'All done'});
    });

    test('photo: multipart with the file part and the key', () async {
      late String body;
      final s = _setup((_, b) async {
        body = b;
        return jsonBody(_taskJson(state: 'SUBMITTED'));
      });
      await s.repository.submitPhoto(
        't1',
        bytes: utf8.encode('JPEGDATA'),
        filename: 'proof.jpg',
        contentType: 'image/jpeg',
        key: const IdempotencyKey('k-photo'),
      );
      final r = s.adapter.requests.single;
      expect(r.path, '/tasks/t1/submit');
      expect(r.headers['Idempotency-Key'], 'k-photo');
      expect(
        r.headers['content-type'] ?? r.contentType,
        contains('multipart/form-data'),
      );
      expect(body, contains('name="file"'));
      expect(body, contains('filename="proof.jpg"'));
      expect(body, contains('image/jpeg'));
      expect(body, contains('JPEGDATA'));
    });

    test('a retry of the same attempt reuses the key', () async {
      final s = _ok(_taskJson(state: 'SUBMITTED'));
      const key = IdempotencyKey('same');
      await s.repository.submitText('t1', 'x', key: key);
      await s.repository.submitPhoto(
        't1',
        bytes: const [1, 2, 3],
        filename: 'p.jpg',
        contentType: 'image/jpeg',
        key: key,
      );
      expect(s.adapter.requests.map((r) => r.headers['Idempotency-Key']), [
        'same',
        'same',
      ]);
    });

    test('deadline_passed surfaces its code', () async {
      final s = _setup(
        (_, _) async => jsonBody({'error': 'deadline_passed'}, status: 409),
      );
      await expectLater(
        s.repository.submitText('t1', 'x', key: IdempotencyKey.generate()),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'deadline_passed'),
        ),
      );
    });
  });
}
