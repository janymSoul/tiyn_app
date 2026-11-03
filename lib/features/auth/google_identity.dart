import 'package:google_sign_in/google_sign_in.dart';

class GoogleIdentity {
  GoogleIdentity({required this.serverClientId});

  final String? serverClientId;
  Future<void>? _initialised;

  Future<void> _init() => _initialised ??= GoogleSignIn.instance.initialize(
    serverClientId: serverClientId,
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
