import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({required this.code, this.statusCode});

  factory ApiException.fromDio(DioException e) {
    final statusCode = e.response?.statusCode;
    final code = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => 'timeout',
      _ when e.response == null => 'network_error',
      _ => _bodyCode(e.response?.data) ?? 'unknown_error',
    };
    return ApiException(code: code, statusCode: statusCode);
  }

  final String code;
  final int? statusCode;

  bool get isUnauthenticated => statusCode == 401;
  bool get isNetwork => code == 'network_error' || code == 'timeout';
  bool get isRetryable =>
      isNetwork ||
      (statusCode != null && statusCode! >= 500) ||
      code == 'concurrent_modification';

  static String? _bodyCode(Object? data) {
    if (data is Map) {
      final error = data['error'];
      if (error is String) return error;
    }
    return null;
  }

  @override
  String toString() => 'ApiException($statusCode, $code)';
}
