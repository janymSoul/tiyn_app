import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config.dart';

class GoogleIdentity {
  Future<void>? _initialised;

  Future<void> _init() => _initialised ??= GoogleSignIn.instance.initialize(
    serverClientId: AppConfig.googleServerClientId.isEmpty
        ? null
        : AppConfig.googleServerClientId,
  );

  Future<String> idToken() async {
    await _init();
    final account = await GoogleSignIn.instance.authenticate();
    final token = account.authentication.idToken;
    if (token == null) {
      throw StateError('Google returned no ID token');
    }
    return token;
  }

  Future<void> signOut() async {
    await _init();
    await GoogleSignIn.instance.signOut();
  }
}
