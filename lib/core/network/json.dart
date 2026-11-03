import 'package:tiyn_app/core/network/api_exception.dart';

Map<String, Object?> asMap(Object? json) {
  if (json is Map<String, Object?>) return json;
  throw const ApiException(code: 'invalid_response');
}

List<Object?> asList(Object? json) {
  if (json is List<Object?>) return json;
  throw const ApiException(code: 'invalid_response');
}
