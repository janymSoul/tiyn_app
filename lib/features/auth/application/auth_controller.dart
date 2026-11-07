import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/app/providers.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/session/session_end.dart';
import 'package:tiyn_app/core/session/session_events.dart';
import 'package:tiyn_app/features/auth/data/auth_repository.dart';
import 'package:tiyn_app/features/auth/data/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(apiClientProvider),
    tokens: ref.watch(tokenStorageProvider),
    google: ref.watch(googleIdentityProvider),
  );
});

class AuthController extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    ref.listen(sessionExpiredProvider, (_, _) => _onSessionExpired());
    final repository = ref.read(authRepositoryProvider);
    if (!await repository.hasToken()) return null;
    try {
      return await repository.me();
    } on ApiException catch (e) {
      if (e.isUnauthenticated) {
        await repository.signOut();
        return null;
      }
      rethrow;
    }
  }

  void signedIn(User user) => state = AsyncData(user);

  Future<void> signOut() async {
    try {
      await ref
          .read(sessionEndHooksProvider)
          .handler
          .beginSignOut()
          .timeout(const Duration(seconds: 1));
    } on Object {
      // Never let device cleanup hold up or fail a sign-out.
    }
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }

  Future<void> _onSessionExpired() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(
  AuthController.new,
);

final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authControllerProvider.select((s) => s.value?.id)),
);
