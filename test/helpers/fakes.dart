import 'package:tiyn_app/core/storage/token_storage.dart';
import 'package:tiyn_app/features/auth/data/google_identity.dart';

class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage([this.token]);

  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;

  @override
  Future<void> clear() async => token = null;
}

class FakeGoogleIdentity implements GoogleIdentity {
  FakeGoogleIdentity({
    this.credential = (idToken: 'google-id-token', email: 'user@example.com'),
    this.signInError,
  });

  GoogleCredential credential;
  Object? signInError;
  int signOutCalls = 0;

  @override
  String? get serverClientId => null;

  @override
  Future<GoogleCredential> signIn() async {
    final error = signInError;
    if (error != null) throw error;
    return credential;
  }

  @override
  Future<void> signOut() async => signOutCalls++;
}
