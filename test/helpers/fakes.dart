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
  @override
  String? get serverClientId => null;

  @override
  Future<String> idToken() async => 'google-id-token';

  @override
  Future<void> signOut() async {}
}
