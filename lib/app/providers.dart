import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/app/config.dart';
import 'package:tiyn_app/core/network/api_client.dart';
import 'package:tiyn_app/core/session/session_events.dart';
import 'package:tiyn_app/core/storage/token_storage.dart';
import 'package:tiyn_app/features/auth/data/google_identity.dart';

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
    onUnauthorized: () => ref.read(sessionExpiredProvider.notifier).expired(),
  );
});
