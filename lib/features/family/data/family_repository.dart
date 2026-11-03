import 'package:tiyn_app/core/network/api_client.dart';
import 'package:tiyn_app/core/network/json.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';

class FamilyRepository {
  FamilyRepository(this._api);

  final ApiClient _api;

  Future<List<FamilyMember>> members() => _api.get(
    '/family',
    decode: (json) =>
        asList(asMap(json)['members'])
            .map((m) => FamilyMember.fromJson(asMap(m)))
            .toList(),
  );

  Future<FamilyMember> join(String code) => _api.post(
    '/links/join',
    body: {'code': code.trim()},
    decode: (json) {
      final parent = asMap(asMap(json)['parent']);
      return FamilyMember(
        id: parent['id'] as String,
        role: Role.parent,
        displayName: parent['displayName'] as String,
      );
    },
  );
}
