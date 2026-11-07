import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/network/api_client.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';
import 'package:tiyn_app/features/teen/data/dashboard.dart';
import 'package:tiyn_app/features/teen/data/dashboard_repository.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/fakes.dart';

Map<String, Object?> _chore({
  String id = 'c1',
  String state = 'ASSIGNED',
  Object? milestoneId,
  bool withMilestoneKey = true,
}) => {
  'id': id,
  'kind': 'TASK',
  'title': 'Wash dishes',
  'description': 'All of them',
  'rewardAmount': 150000,
  'penaltyAmount': 10000,
  'currency': 'KZT',
  'state': state,
  'deadlineAt': '2026-11-03T18:00:00Z',
  if (withMilestoneKey) 'milestoneId': milestoneId,
};

// The shape in docs/api.md, including the parts Phase 1 does not show.
Map<String, Object?> _body() => {
  'balance': {
    'balanceAmount': 1500000,
    'lockedAmount': 200000,
    'availableAmount': 1300000,
    'currency': 'KZT',
  },
  'pendingAmount': 150000,
  'chores': [_chore(milestoneId: 'm1')],
  'milestones': [
    {
      ..._chore(id: 'm1', withMilestoneKey: false),
      'kind': 'MILESTONE',
      'approvedTasks': 2,
      'totalTasks': 5,
    },
  ],
  'goals': [
    {
      'id': 'g',
      'name': 'Bike',
      'targetAmount': 2000000,
      'savedAmount': 0,
      'currency': 'KZT',
    },
  ],
  'openPayout': {
    'id': 'p',
    'parentId': 'x',
    'amount': 5,
    'currency': 'KZT',
    'requestedAt': '2026-11-01T00:00:00Z',
  },
};

Matcher _invalidResponse() => throwsA(
  isA<ApiException>().having((e) => e.code, 'code', 'invalid_response'),
);

void main() {
  group('Dashboard.fromJson', () {
    test('decodes the documented response', () {
      final d = Dashboard.fromJson(_body());
      expect(d.balance.balance, const Money.kzt(1500000));
      expect(d.balance.locked, const Money.kzt(200000));
      expect(d.balance.available, const Money.kzt(1300000));
      expect(d.pending, const Money.kzt(150000));

      final chore = d.chores.single;
      expect(chore.id, 'c1');
      expect(chore.kind, TaskKind.task);
      expect(chore.title, 'Wash dishes');
      expect(chore.description, 'All of them');
      expect(chore.reward, const Money.kzt(150000));
      expect(chore.penalty, const Money.kzt(10000));
      expect(chore.state, TaskState.assigned);
      expect(chore.deadlineAt, DateTime.utc(2026, 11, 3, 18));
      expect(chore.milestoneId, 'm1');
      expect(chore.approvedTasks, isNull);

      final milestone = d.milestones.single;
      expect(milestone.kind, TaskKind.milestone);
      expect(milestone.milestoneId, isNull);
      expect(milestone.approvedTasks, 2);
      expect(milestone.totalTasks, 5);
    });

    test('milestoneId may be missing, null, or present', () {
      Dashboard with_(Map<String, Object?> chore) => Dashboard.fromJson({
        ..._body(),
        'chores': [chore],
      });

      expect(
        with_(_chore(withMilestoneKey: false)).chores.single.milestoneId,
        isNull,
        reason: 'older backend: field absent',
      );
      expect(with_(_chore()).chores.single.milestoneId, isNull);
      expect(with_(_chore(milestoneId: 'm9')).chores.single.milestoneId, 'm9');
    });

    test('empty lists are fine', () {
      final d = Dashboard.fromJson({
        ..._body(),
        'chores': <Object?>[],
        'milestones': <Object?>[],
        'pendingAmount': 0,
      });
      expect(d.chores, isEmpty);
      expect(d.milestones, isEmpty);
      expect(d.pending, Money.zero);
    });

    test('goals and the payout may be absent', () {
      final json = _body()
        ..remove('goals')
        ..remove('openPayout');
      expect(() => Dashboard.fromJson(json), returnsNormally);
    });

    test('a missing description is empty', () {
      final chore = _chore()..remove('description');
      final d = Dashboard.fromJson({
        ..._body(),
        'chores': [chore],
      });
      expect(d.chores.single.description, '');
    });

    test('an unknown state fails loudly', () {
      final json = {
        ..._body(),
        'chores': [_chore(state: 'PAUSED')],
      };
      expect(() => Dashboard.fromJson(json), _invalidResponse());
    });

    test('a foreign currency fails loudly', () {
      final json = _body();
      (json['balance']! as Map<String, Object?>)['currency'] = 'USD';
      expect(() => Dashboard.fromJson(json), _invalidResponse());
    });

    test('a missing balance fails loudly', () {
      expect(
        () => Dashboard.fromJson(_body()..remove('balance')),
        _invalidResponse(),
      );
    });

    test('a bad pendingAmount fails loudly', () {
      expect(
        () => Dashboard.fromJson(_body()..['pendingAmount'] = '150000'),
        _invalidResponse(),
      );
      expect(
        () => Dashboard.fromJson(_body()..remove('pendingAmount')),
        _invalidResponse(),
      );
    });

    test('chores must be a list', () {
      expect(
        () => Dashboard.fromJson(_body()..['chores'] = 'none'),
        _invalidResponse(),
      );
    });
  });

  group('DashboardRepository', () {
    DashboardRepository repo(FakeHandler handler) {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter(handler);
      return DashboardRepository(
        ApiClient(
          baseUrl: Uri.parse('https://api.test'),
          tokens: FakeTokenStorage('t'),
          onUnauthorized: () {},
          dio: dio,
        ),
      );
    }

    test('GET /dashboard', () async {
      late RequestOptions seen;
      final r = repo((o, _) async {
        seen = o;
        return jsonBody(_body());
      });
      final d = await r.load();
      expect(seen.method, 'GET');
      expect(seen.path, '/dashboard');
      expect(d.pending, const Money.kzt(150000));
    });

    test('a parent gets 403, surfaced as forbidden', () async {
      final r = repo(
        (_, _) async => jsonBody({'error': 'forbidden'}, status: 403),
      );
      await expectLater(
        r.load(),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'forbidden')),
      );
    });

    test('a broken body is invalid_response', () async {
      final r = repo((_, _) async => jsonBody({'balance': 1}));
      await expectLater(r.load(), _invalidResponse());
    });
  });
}
