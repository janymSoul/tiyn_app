import 'package:tiyn_app/core/network/api_client.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/core/storage/token_storage.dart';
import 'package:tiyn_app/features/auth/data/google_identity.dart';
import 'package:tiyn_app/features/auth/data/user.dart';

class AuthRepository {
  AuthRepository({
    required this._api,
    required this._tokens,
    required this._google,
  });

  final ApiClient _api;
  final TokenStorage _tokens;
  final GoogleIdentity _google;

  Future<bool> hasToken() async => await _tokens.read() != null;

  Future<User> me() async => User.fromJson(await _api.getJson('/me'));

  Future<User> signInWithGoogle({required Role role}) async {
    return signInWithIdToken(await _google.idToken(), role: role);
  }

  Future<User> signInWithIdToken(String idToken, {required Role role}) async {
    final json = await _api.postJson(
      '/auth/google',
      body: {'idToken': idToken, 'role': role.wire},
    );
    await _tokens.write(json['token'] as String);
    return User.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<void> signOut() async {
    await _tokens.clear();
    await _google.signOut();
  }
}
