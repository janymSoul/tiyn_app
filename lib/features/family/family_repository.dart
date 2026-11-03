import '../../core/api_client.dart';
import '../auth/user.dart';
import 'family_member.dart';

class FamilyRepository {
  FamilyRepository(this._api);

  final ApiClient _api;

  Future<List<FamilyMember>> members() async {
    final json = await _api.getJson('/family');
    return (json['members'] as List)
        .map((m) => FamilyMember.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<FamilyMember> join(String code) async {
    final json = await _api.postJson(
      '/links/join',
      body: {'code': code.trim()},
    );
    final parent = json['parent'] as Map<String, dynamic>;
    return FamilyMember(
      id: parent['id'] as String,
      role: Role.parent,
      displayName: parent['displayName'] as String,
    );
  }
}
