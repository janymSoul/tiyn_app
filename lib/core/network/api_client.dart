import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/idempotency_key.dart';
import 'package:tiyn_app/core/storage/token_storage.dart';

typedef UnauthorizedHandler = void Function();

typedef JsonDecoder<T> = T Function(Object? json);

class ApiClient {
  ApiClient({
    required Uri baseUrl,
    required this._tokens,
    required this._onUnauthorized,
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl.toString(),
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 20),
               sendTimeout: const Duration(seconds: 60),
               responseType: ResponseType.json,
             ),
           ) {
    _dio.interceptors.addAll([
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokens.read();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
      InterceptorsWrapper(
        onError: (e, handler) {
          final hadToken = e.requestOptions.headers.containsKey(
            'Authorization',
          );
          if (e.response?.statusCode == 401 && hadToken) {
            _onUnauthorized();
          }
          handler.next(e);
        },
      ),
      if (kDebugMode) _DebugLogInterceptor(),
    ]);
  }

  final Dio _dio;
  final TokenStorage _tokens;
  final UnauthorizedHandler _onUnauthorized;

  Future<T> get<T>(
    String path, {
    Map<String, Object?>? query,
    required JsonDecoder<T> decode,
  }) => _send(() => _dio.get<Object?>(path, queryParameters: query), decode);

  Future<T> post<T>(
    String path, {
    Object? body,
    IdempotencyKey? idempotencyKey,
    required JsonDecoder<T> decode,
  }) => _send(
    () =>
        _dio.post<Object?>(path, data: body, options: _options(idempotencyKey)),
    decode,
  );

  Future<void> postNoContent(
    String path, {
    Object? body,
    IdempotencyKey? idempotencyKey,
  }) => _send(
    () =>
        _dio.post<Object?>(path, data: body, options: _options(idempotencyKey)),
    (_) {},
  );

  Future<void> put(String path, {Object? body}) =>
      _send(() => _dio.put<Object?>(path, data: body), (_) {});

  Future<void> delete(String path, {Object? body}) =>
      _send(() => _dio.delete<Object?>(path, data: body), (_) {});

  Future<T> postMultipart<T>(
    String path, {
    required List<int> bytes,
    required String filename,
    required String contentType,
    String fileField = 'file',
    Map<String, String> fields = const {},
    IdempotencyKey? idempotencyKey,
    required JsonDecoder<T> decode,
  }) => _send(
    () => _dio.post<Object?>(
      path,
      data: FormData.fromMap({
        ...fields,
        fileField: MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(contentType),
        ),
      }),
      options: _options(idempotencyKey),
    ),
    decode,
  );

  Options? _options(IdempotencyKey? key) =>
      key == null ? null : Options(headers: {'Idempotency-Key': key.value});

  Future<T> _send<T>(
    Future<Response<Object?>> Function() call,
    JsonDecoder<T> decode,
  ) async {
    try {
      final response = await call();
      final data = response.data;
      return decode(data is String && data.isEmpty ? null : data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

class _DebugLogInterceptor extends Interceptor {
  static const _startKey = 'startedAt';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(err.requestOptions, err.response?.statusCode);
    handler.next(err);
  }

  void _log(RequestOptions options, int? status) {
    final started = options.extra[_startKey];
    final ms = started is DateTime
        ? DateTime.now().difference(started).inMilliseconds
        : null;
    debugPrint(
      '${options.method} ${options.uri.path} -> ${status ?? 'ERR'} (${ms}ms)',
    );
  }
}
