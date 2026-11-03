import 'package:google_sign_in/google_sign_in.dart';

typedef GoogleCredential = ({String idToken, String email});

class GoogleIdentity {
  GoogleIdentity({required this.serverClientId});

  final String? serverClientId;
  Future<void>? _initialised;

  Future<void> _init() => _initialised ??= GoogleSignIn.instance.initialize(
    serverClientId: serverClientId,
  );

  Future<GoogleCredential> signIn() async {
    await _init();
    final account = await GoogleSignIn.instance.authenticate();
    final token = account.authentication.idToken;
    if (token == null) {
      throw StateError('Google returned no ID token');
    }
    return (idToken: token, email: account.email);
  }

  Future<void> signOut() async {
    await _init();
    await GoogleSignIn.instance.signOut();
  }
}
