// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_User', json, ($checkedConvert) {
      final val = _User(
        id: $checkedConvert('id', (v) => v as String),
        role: $checkedConvert('role', (v) => $enumDecode(_$RoleEnumMap, v)),
        displayName: $checkedConvert('displayName', (v) => v as String),
        joinCode: $checkedConvert('joinCode', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'role': _$RoleEnumMap[instance.role]!,
  'displayName': instance.displayName,
  'joinCode': instance.joinCode,
};

const _$RoleEnumMap = {Role.parent: 'PARENT', Role.teen: 'TEEN'};
