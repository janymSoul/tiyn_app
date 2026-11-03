import 'package:dio/dio.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/storage/token_storage.dart';
import 'package:uuid/uuid.dart';

typedef UnauthorizedHandler = void Function();

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
             ),
           ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokens.read();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
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
    );
  }

  static const _uuid = Uuid();
  final Dio _dio;
  final TokenStorage _tokens;
  final UnauthorizedHandler _onUnauthorized;

  static String newIdempotencyKey() => _uuid.v4();

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) =>
      _send(() => _dio.get<Map<String, dynamic>>(path, queryParameters: query));

  Future<Map<String, dynamic>> postJson(
    String path, {
    Object? body,
    String? idempotencyKey,
  }) => _send(
    () => _dio.post<Map<String, dynamic>>(
      path,
      data: body,
      options: idempotencyKey == null
          ? null
          : Options(headers: {'Idempotency-Key': idempotencyKey}),
    ),
  );

  Future<Map<String, dynamic>> _send(
    Future<Response<Map<String, dynamic>>> Function() call,
  ) async {
    try {
      final response = await call();
      return response.data ?? const {};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
