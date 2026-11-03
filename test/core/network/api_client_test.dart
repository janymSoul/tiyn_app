import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/network/api_client.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/idempotency_key.dart';
import 'package:tiyn_app/core/network/json.dart';
import 'package:tiyn_app/features/auth/data/user.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/fakes.dart';

ApiClient _client(
  FakeAdapter adapter, {
  String? token,
  void Function()? onUnauthorized,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = adapter;
  return ApiClient(
    baseUrl: Uri.parse('https://api.test'),
    tokens: FakeTokenStorage(token),
    onUnauthorized: onUnauthorized ?? () {},
    dio: dio,
  );
}

void main() {
  test('decodes an object body', () async {
    final api = _client(FakeAdapter((_, _) async => jsonBody({'id': '1'})));
    final id = await api.get('/me', decode: (j) => asMap(j)['id']);
    expect(id, '1');
  });

  test('decodes an array body', () async {
    final api = _client(FakeAdapter((_, _) async => jsonBody([1, 2, 3])));
    final list = await api.get('/tasks', decode: asList);
    expect(list, [1, 2, 3]);
  });

  test('a wrong body shape is invalid_response', () async {
    final api = _client(FakeAdapter((_, _) async => jsonBody([1])));
    expect(
      api.get('/me', decode: asMap),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'invalid_response'),
      ),
    );
  });

  test('a model failing checked fromJson is invalid_response', () async {
    final api = _client(FakeAdapter((_, _) async => jsonBody({'id': 1})));
    expect(
      api.get('/me', decode: (j) => User.fromJson(asMap(j))),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'invalid_response'),
      ),
    );
  });

  test('204 passes null to decode', () async {
    final api = _client(FakeAdapter((_, _) async => emptyBody(204)));
    final seen = <Object?>[];
    await api.post('/x', decode: (j) => seen.add(j));
    expect(seen, [null]);
  });

  test('backend error code and status become ApiException', () async {
    final api = _client(
      FakeAdapter(
        (_, _) async => jsonBody({'error': 'invalid_join_code'}, status: 422),
      ),
    );
    expect(
      api.post('/links/join', decode: (_) {}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'invalid_join_code')
            .having((e) => e.statusCode, 'statusCode', 422),
      ),
    );
  });

  test('connection error is network_error', () async {
    final api = _client(
      FakeAdapter(
        (o, _) async => throw DioException.connectionError(
          requestOptions: o,
          reason: 'offline',
        ),
      ),
    );
    expect(
      api.get('/me', decode: (_) {}),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'network_error'),
      ),
    );
  });

  test('receive timeout is timeout', () async {
    final api = _client(
      FakeAdapter(
        (o, _) async => throw DioException.receiveTimeout(
          timeout: const Duration(seconds: 20),
          requestOptions: o,
        ),
      ),
    );
    expect(
      api.get('/me', decode: (_) {}),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'timeout')),
    );
  });

  test('sends Idempotency-Key only when given', () async {
    final adapter = FakeAdapter((_, _) async => emptyBody(204));
    final api = _client(adapter);
    final key = IdempotencyKey.generate();
    await api.postNoContent('/a', idempotencyKey: key);
    await api.postNoContent('/b');
    expect(adapter.requests[0].headers['Idempotency-Key'], key.value);
    expect(adapter.requests[1].headers.containsKey('Idempotency-Key'), isFalse);
  });

  test('401 with a token calls onUnauthorized once', () async {
    var calls = 0;
    final api = _client(
      FakeAdapter(
        (_, _) async => jsonBody({'error': 'unauthenticated'}, status: 401),
      ),
      token: 'jwt',
      onUnauthorized: () => calls++,
    );
    await expectLater(
      api.get('/me', decode: (_) {}),
      throwsA(isA<ApiException>()),
    );
    expect(calls, 1);
  });

  test('401 without a token does not call onUnauthorized', () async {
    var calls = 0;
    final api = _client(
      FakeAdapter(
        (_, _) async => jsonBody({'error': 'invalid_identity'}, status: 401),
      ),
      onUnauthorized: () => calls++,
    );
    await expectLater(
      api.post('/auth/google', decode: (_) {}),
      throwsA(
        isA<ApiException>().having((e) => e.isUnauthenticated, '401', true),
      ),
    );
    expect(calls, 0);
  });

  test('adds the bearer token when present', () async {
    final adapter = FakeAdapter((_, _) async => jsonBody({}));
    await _client(adapter, token: 'jwt').get('/me', decode: (_) {});
    expect(adapter.requests.single.headers['Authorization'], 'Bearer jwt');
  });

  test('multipart request carries a file part with its content type', () async {
    String? body;
    final api = _client(
      FakeAdapter((_, b) async {
        body = b;
        return jsonBody({'ok': true});
      }),
    );
    await api.postMultipart(
      '/proof',
      bytes: utf8.encode('IMG'),
      filename: 'p.jpg',
      contentType: 'image/jpeg',
      fields: {'note': 'hi'},
      decode: (_) {},
    );
    expect(body, contains('name="file"'));
    expect(body, contains('filename="p.jpg"'));
    expect(body!.toLowerCase(), contains('content-type: image/jpeg'));
    expect(body, contains('name="note"'));
  });

  test('put and delete succeed on 204', () async {
    final adapter = FakeAdapter((_, _) async => emptyBody(204));
    final api = _client(adapter);
    await api.put('/devices', body: {'t': 1});
    await api.delete('/links/1');
    expect(adapter.requests.map((r) => r.method), ['PUT', 'DELETE']);
  });
}
