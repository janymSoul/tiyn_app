import 'package:tiyn_app/core/network/api_client.dart';

class DeviceRepository {
  DeviceRepository(this._api);

  final ApiClient _api;

  Future<void> register({required String token, required String locale}) =>
      _api.put(
        '/devices',
        body: {'token': token, 'platform': 'ANDROID', 'locale': locale},
      );

  /// On behalf of [authToken], because by the time this runs the session is
  /// usually already gone from storage.
  Future<void> unregister({required String token, required String authToken}) =>
      _api.delete('/devices', body: {'token': token}, authToken: authToken);
}
