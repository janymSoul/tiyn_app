import 'package:tiyn_app/core/network/api_client.dart';
import 'package:tiyn_app/core/network/json.dart';
import 'package:tiyn_app/features/teen/data/dashboard.dart';

class DashboardRepository {
  DashboardRepository(this._api);

  final ApiClient _api;

  Future<Dashboard> load() =>
      _api.get('/dashboard', decode: (json) => Dashboard.fromJson(asMap(json)));
}
