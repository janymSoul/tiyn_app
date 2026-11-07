// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proof.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Proof _$ProofFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_Proof', json, ($checkedConvert) {
      final val = _Proof(
        attemptNo: $checkedConvert('attemptNo', (v) => (v as num).toInt()),
        imageUrl: $checkedConvert('imageUrl', (v) => v as String?),
        text: $checkedConvert('text', (v) => v as String?),
        createdAt: $checkedConvert(
          'createdAt',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ProofToJson(_Proof instance) => <String, dynamic>{
  'attemptNo': instance.attemptNo,
  'imageUrl': instance.imageUrl,
  'text': instance.text,
  'createdAt': instance.createdAt.toIso8601String(),
};
