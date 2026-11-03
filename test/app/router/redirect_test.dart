import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/app/router/redirect.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';

const _parent = User(id: 'p', role: Role.parent, displayName: 'P');
const _teen = User(id: 't', role: Role.teen, displayName: 'T');
const _link = FamilyMember(id: 'p', role: Role.parent, displayName: 'P');

AsyncValue<User?> _authData(User? user) => AsyncData(user);
const AsyncValue<User?> _authLoading = AsyncLoading();
final AsyncValue<User?> _authError = AsyncError(
  Exception('x'),
  StackTrace.empty,
);

const AsyncValue<List<FamilyMember>> _noFamily = AsyncData([]);
const AsyncValue<List<FamilyMember>> _linked = AsyncData([_link]);
const AsyncValue<List<FamilyMember>> _familyLoading = AsyncLoading();
final AsyncValue<List<FamilyMember>> _familyError = AsyncError(
  Exception('x'),
  StackTrace.empty,
);

void main() {
  final cases =
      <
        ({
          String name,
          AsyncValue<User?> auth,
          AsyncValue<List<FamilyMember>> family,
          String location,
          String? expected,
        })
      >[
        (
          name: 'auth loading at entry',
          auth: _authLoading,
          family: _noFamily,
          location: '/',
          expected: '/splash',
        ),
        (
          name: 'auth loading already on splash',
          auth: _authLoading,
          family: _noFamily,
          location: '/splash',
          expected: null,
        ),
        (
          name: 'auth loading on sign-in stays (sign-in in progress)',
          auth: _authLoading,
          family: _noFamily,
          location: '/sign-in',
          expected: null,
        ),
        (
          name: 'auth error elsewhere goes to splash',
          auth: _authError,
          family: _noFamily,
          location: '/teen/home',
          expected: '/splash',
        ),
        (
          name: 'auth error on sign-in stays (shows its own error)',
          auth: _authError,
          family: _noFamily,
          location: '/sign-in',
          expected: null,
        ),
        (
          name: 'signed out at entry',
          auth: _authData(null),
          family: _noFamily,
          location: '/',
          expected: '/sign-in',
        ),
        (
          name: 'signed out on splash',
          auth: _authData(null),
          family: _noFamily,
          location: '/splash',
          expected: '/sign-in',
        ),
        (
          name: 'signed out already on sign-in',
          auth: _authData(null),
          family: _noFamily,
          location: '/sign-in',
          expected: null,
        ),
        (
          name: 'signed out inside the app',
          auth: _authData(null),
          family: _noFamily,
          location: '/parent/home',
          expected: '/sign-in',
        ),
        (
          name: 'teen family loading',
          auth: _authData(_teen),
          family: _familyLoading,
          location: '/sign-in',
          expected: '/splash',
        ),
        (
          name: 'teen family error',
          auth: _authData(_teen),
          family: _familyError,
          location: '/splash',
          expected: null,
        ),
        (
          name: 'teen family error elsewhere',
          auth: _authData(_teen),
          family: _familyError,
          location: '/teen/home',
          expected: '/splash',
        ),
        (
          name: 'unlinked teen at entry',
          auth: _authData(_teen),
          family: _noFamily,
          location: '/',
          expected: '/teen/join',
        ),
        (
          name: 'unlinked teen on join stays',
          auth: _authData(_teen),
          family: _noFamily,
          location: '/teen/join',
          expected: null,
        ),
        (
          name: 'unlinked teen cannot reach home',
          auth: _authData(_teen),
          family: _noFamily,
          location: '/teen/home',
          expected: '/teen/join',
        ),
        (
          name: 'linked teen leaves join',
          auth: _authData(_teen),
          family: _linked,
          location: '/teen/join',
          expected: '/teen/home',
        ),
        (
          name: 'linked teen from splash',
          auth: _authData(_teen),
          family: _linked,
          location: '/splash',
          expected: '/teen/home',
        ),
        (
          name: 'linked teen from sign-in',
          auth: _authData(_teen),
          family: _linked,
          location: '/sign-in',
          expected: '/teen/home',
        ),
        (
          name: 'linked teen from root',
          auth: _authData(_teen),
          family: _linked,
          location: '/',
          expected: '/teen/home',
        ),
        (
          name: 'linked teen kept out of parent routes',
          auth: _authData(_teen),
          family: _linked,
          location: '/parent/review',
          expected: '/teen/home',
        ),
        (
          name: 'linked teen on a teen tab stays',
          auth: _authData(_teen),
          family: _linked,
          location: '/teen/goals',
          expected: null,
        ),
        (
          name: 'parent at entry',
          auth: _authData(_parent),
          family: _noFamily,
          location: '/',
          expected: '/parent/home',
        ),
        (
          name: 'parent from splash',
          auth: _authData(_parent),
          family: _familyLoading,
          location: '/splash',
          expected: '/parent/home',
        ),
        (
          name: 'parent from sign-in',
          auth: _authData(_parent),
          family: _noFamily,
          location: '/sign-in',
          expected: '/parent/home',
        ),
        (
          name: 'parent kept out of teen routes',
          auth: _authData(_parent),
          family: _noFamily,
          location: '/teen/home',
          expected: '/parent/home',
        ),
        (
          name: 'parent on a parent tab stays',
          auth: _authData(_parent),
          family: _noFamily,
          location: '/parent/review',
          expected: null,
        ),
      ];

  for (final c in cases) {
    test(c.name, () {
      expect(
        resolveRedirect(auth: c.auth, family: c.family, location: c.location),
        c.expected,
      );
    });
  }
}
