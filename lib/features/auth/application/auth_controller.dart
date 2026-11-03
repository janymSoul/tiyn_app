import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/app/config.dart';
import 'package:tiyn_app/core/network/api_client.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/core/storage/token_storage.dart';
import 'package:tiyn_app/features/auth/data/auth_repository.dart';
import 'package:tiyn_app/features/auth/data/google_identity.dart';
import 'package:tiyn_app/features/auth/data/user.dart';

final tokenStorageProvider = Provider<TokenStorage>((_) => TokenStorage());

final googleIdentityProvider = Provider<GoogleIdentity>(
  (ref) => GoogleIdentity(
    serverClientId: ref.watch(appConfigProvider).googleServerClientId,
  ),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: ref.watch(appConfigProvider).apiBaseUrl,
    tokens: ref.watch(tokenStorageProvider),
    onUnauthorized: () =>
        ref.read(authControllerProvider.notifier).sessionExpired(),
  );
});

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

  Future<void> signIn(Role role) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithGoogle(role: role),
    );
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }

  void sessionExpired() {
    ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(
  AuthController.new,
);
