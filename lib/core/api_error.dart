import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException({required this.code, this.statusCode});

  final String code;
  final int? statusCode;

  bool get isUnauthenticated => statusCode == 401;

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    final code = data is Map && data['error'] is String
        ? data['error'] as String
        : (e.response == null ? 'network_error' : 'unknown_error');
    return ApiException(code: code, statusCode: e.response?.statusCode);
  }

  @override
  String toString() => 'ApiException($statusCode, $code)';
}
