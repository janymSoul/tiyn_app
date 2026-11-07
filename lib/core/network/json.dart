import 'package:tiyn_app/core/network/api_exception.dart';

Map<String, Object?> asMap(Object? json) {
  if (json is Map<String, Object?>) return json;
  throw const ApiException(code: 'invalid_response');
}

List<Object?> asList(Object? json) {
  if (json is List<Object?>) return json;
  throw const ApiException(code: 'invalid_response');
}

// Field readers for models decoded by hand. Any mismatch is `invalid_response`,
// so a surprising backend never turns into a silent default.

String reqString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is String) return value;
  throw const ApiException(code: 'invalid_response');
}

String? optString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is String) return value;
  throw const ApiException(code: 'invalid_response');
}

int? optInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is int) return value;
  throw const ApiException(code: 'invalid_response');
}

DateTime reqTime(Map<String, Object?> map, String key) =>
    optTime(map, key) ?? (throw const ApiException(code: 'invalid_response'));

DateTime? optTime(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  final parsed = value is String ? DateTime.tryParse(value) : null;
  if (parsed == null) throw const ApiException(code: 'invalid_response');
  return parsed.toUtc();
}
