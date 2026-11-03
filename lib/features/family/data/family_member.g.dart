// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FamilyMember _$FamilyMemberFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_FamilyMember', json, ($checkedConvert) {
      final val = _FamilyMember(
        id: $checkedConvert('id', (v) => v as String),
        role: $checkedConvert('role', (v) => $enumDecode(_$RoleEnumMap, v)),
        displayName: $checkedConvert('displayName', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$FamilyMemberToJson(_FamilyMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': _$RoleEnumMap[instance.role]!,
      'displayName': instance.displayName,
    };

const _$RoleEnumMap = {Role.parent: 'PARENT', Role.teen: 'TEEN'};
