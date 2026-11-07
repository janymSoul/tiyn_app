import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/network/api_client.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/paged_list.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/fakes.dart';

PagedListReader _reader(FakeAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = adapter;
  return PagedListReader(
    ApiClient(
      baseUrl: Uri.parse('https://api.test'),
      tokens: FakeTokenStorage('token'),
      onUnauthorized: () {},
      dio: dio,
    ),
  );
}

Future<List<int>> _read(PagedListReader r, {Map<String, Object?>? query}) =>
    r.readAll<int>(
      '/things',
      query: query ?? const {},
      decodeItem: (j) => j is int ? j : throw const ApiException(code: 'bad'),
    );

Matcher _apiError(String code) =>
    isA<ApiException>().having((e) => e.code, 'code', code);

Map<String, Object?> _page(List<int> items, [String? next]) => {
  'items': items,
  'nextCursor': ?next,
};

Object? _cursor(RequestOptions o) => o.queryParameters['cursor'];

void main() {
  test('a bare array is one page with no next page', () async {
    final a = FakeAdapter((_, _) async => jsonBody([1, 2, 3]));
    expect(await _read(_reader(a)), [1, 2, 3]);
    expect(a.requests, hasLength(1));
    expect(a.requests.single.queryParameters, {'limit': 100});
  });

  test('an envelope without nextCursor is one page', () async {
    final a = FakeAdapter((_, _) async => jsonBody(_page([1, 2])));
    expect(await _read(_reader(a)), [1, 2]);
    expect(a.requests, hasLength(1));
  });

  test('an empty envelope and an empty array are empty lists', () async {
    expect(
      await _read(_reader(FakeAdapter((_, _) async => jsonBody(_page([]))))),
      isEmpty,
    );
    expect(
      await _read(_reader(FakeAdapter((_, _) async => jsonBody([])))),
      isEmpty,
    );
  });

  test('three pages are followed in order with the same filters', () async {
    final a = FakeAdapter((o, _) async {
      return jsonBody(switch (_cursor(o)) {
        null => _page([1, 2], 'c1'),
        'c1' => _page([3, 4], 'c2'),
        'c2' => _page([5]),
        _ => fail('unexpected cursor'),
      });
    });
    final items = await _read(_reader(a), query: {'state': 'ASSIGNED'});
    expect(items, [1, 2, 3, 4, 5]);
    expect(a.requests.map((r) => r.queryParameters), [
      {'state': 'ASSIGNED', 'limit': 100},
      {'state': 'ASSIGNED', 'limit': 100, 'cursor': 'c1'},
      {'state': 'ASSIGNED', 'limit': 100, 'cursor': 'c2'},
    ]);
  });

  test('the page cap is an error, not a loop', () async {
    final a = FakeAdapter((_, _) async => jsonBody(_page([1], 'again')));
    await expectLater(_read(_reader(a)), throwsA(_apiError('too_many_pages')));
    expect(a.requests, hasLength(maxPages));
  });

  test('exactly the cap in pages still succeeds', () async {
    var n = 0;
    final a = FakeAdapter((_, _) async {
      n++;
      return jsonBody(n < maxPages ? _page([n], 'c$n') : _page([n]));
    });
    expect(await _read(_reader(a)), hasLength(maxPages));
  });

  group('invalid_cursor', () {
    ResponseBody invalidCursor() =>
        jsonBody({'error': 'invalid_cursor'}, status: 422);

    test('restarts the walk from the first page once', () async {
      var failed = false;
      final a = FakeAdapter((o, _) async {
        switch (_cursor(o)) {
          case null:
            return jsonBody(_page([1], 'c1'));
          case 'c1' when !failed:
            failed = true;
            return invalidCursor();
          case 'c1':
            return jsonBody(_page([2]));
        }
        return fail('unexpected cursor');
      });
      expect(await _read(_reader(a)), [1, 2]);
      expect(a.requests.map(_cursor), [null, 'c1', null, 'c1']);
    });

    test('a second invalid_cursor surfaces as an error', () async {
      final a = FakeAdapter((o, _) async {
        return _cursor(o) == null
            ? jsonBody(_page([1], 'c1'))
            : invalidCursor();
      });
      await expectLater(
        _read(_reader(a)),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'invalid_cursor')
              .having((e) => e.statusCode, 'status', 422),
        ),
      );
      expect(a.requests.map(_cursor), [null, 'c1', null, 'c1']);
    });

    test('other errors are not retried', () async {
      final a = FakeAdapter(
        (_, _) async => jsonBody({'error': 'internal_error'}, status: 500),
      );
      await expectLater(
        _read(_reader(a)),
        throwsA(_apiError('internal_error')),
      );
      expect(a.requests, hasLength(1));
    });
  });

  group('malformed bodies are invalid_response', () {
    for (final (name, body) in <(String, Object?)>[
      ('a string', 'nope'),
      ('an object without items', {'nextCursor': 'c'}),
      (
        'items that are not a list',
        <String, Object?>{'items': <String, Object?>{}},
      ),
      (
        'a non-string nextCursor',
        {
          'items': [1],
          'nextCursor': 5,
        },
      ),
      (
        'an empty nextCursor',
        {
          'items': [1],
          'nextCursor': '',
        },
      ),
    ]) {
      test(name, () async {
        final a = FakeAdapter((_, _) async => jsonBody(body));
        await expectLater(
          _read(_reader(a)),
          throwsA(_apiError('invalid_response')),
        );
      });
    }
  });
}
