import 'package:tiyn_app/core/session/role.dart';

class User {
  const User({
    required this.id,
    required this.role,
    required this.displayName,
    this.joinCode,
  });

  final String id;
  final Role role;
  final String displayName;
  final String? joinCode;

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    role: Role.fromWire(json['role'] as String),
    displayName: json['displayName'] as String,
    joinCode: json['joinCode'] as String?,
  );
}
