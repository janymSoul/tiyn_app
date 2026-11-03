import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/app/router/routes.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';

String? resolveRedirect({
  required AsyncValue<User?> auth,
  required AsyncValue<List<FamilyMember>> family,
  required String location,
}) {
  String? go(String target) => target == location ? null : target;

  // The sign-in screen shows its own progress and errors.
  final authPending = (auth.isLoading && !auth.hasValue) || auth.hasError;
  if (authPending) return location == Routes.signIn ? null : go(Routes.splash);

  final user = auth.value;
  if (user == null) return go(Routes.signIn);

  final atEntry =
      location == '/' || location == Routes.splash || location == Routes.signIn;

  if (user.role == Role.parent) {
    return atEntry || location.startsWith('/teen/')
        ? go(Routes.parentHome)
        : null;
  }

  if (family.isLoading || family.hasError) return go(Routes.splash);
  final members = family.value ?? const [];
  if (members.isEmpty) return go(Routes.teenJoin);
  return atEntry ||
          location == Routes.teenJoin ||
          location.startsWith('/parent/')
      ? go(Routes.teenHome)
      : null;
}
