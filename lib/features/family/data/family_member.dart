import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tiyn_app/core/session/role.dart';

part 'family_member.freezed.dart';
part 'family_member.g.dart';

@freezed
abstract class FamilyMember with _$FamilyMember {
  const factory FamilyMember({
    required String id,
    required Role role,
    required String displayName,
  }) = _FamilyMember;

  factory FamilyMember.fromJson(Map<String, Object?> json) =>
      _$FamilyMemberFromJson(json);
}
