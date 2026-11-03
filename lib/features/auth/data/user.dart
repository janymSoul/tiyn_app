import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tiyn_app/core/session/role.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required Role role,
    required String displayName,
    String? joinCode,
  }) = _User;

  factory User.fromJson(Map<String, Object?> json) => _$UserFromJson(json);
}
