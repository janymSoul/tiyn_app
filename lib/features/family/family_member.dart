import '../auth/user.dart';

class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.role,
    required this.displayName,
  });

  final String id;
  final Role role;
  final String displayName;

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: json['id'] as String,
    role: Role.fromWire(json['role'] as String),
    displayName: json['displayName'] as String,
  );
}
