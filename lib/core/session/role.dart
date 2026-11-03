import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'wire')
enum Role {
  parent('PARENT'),
  teen('TEEN');

  const Role(this.wire);

  final String wire;
}
