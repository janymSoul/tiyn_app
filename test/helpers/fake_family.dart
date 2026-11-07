import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';
import 'package:tiyn_app/features/family/data/family_repository.dart';

FamilyMember teenMember(String id, String name) =>
    FamilyMember(id: id, role: Role.teen, displayName: name);

class FakeFamilyRepository implements FamilyRepository {
  FakeFamilyRepository([List<FamilyMember> members = const []])
    : members_ = List.of(members);

  List<FamilyMember> members_;
  Object? error;
  int calls = 0;

  @override
  Future<List<FamilyMember>> members() async {
    calls++;
    final failure = error;
    if (failure != null) throw failure;
    return List.of(members_);
  }

  @override
  Future<FamilyMember> join(String code) => throw UnimplementedError();
}
