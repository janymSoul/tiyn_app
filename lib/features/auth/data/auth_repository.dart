import 'dart:async';

import 'package:tiyn_app/core/network/api_client.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/json.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/core/storage/token_storage.dart';
import 'package:tiyn_app/features/auth/data/google_identity.dart';
import 'package:tiyn_app/features/auth/data/user.dart';

sealed class SignInOutcome {}

final class SignedIn extends SignInOutcome {
  SignedIn(this.user);

  final User user;
}

final class RoleRequired extends SignInOutcome {}

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

  Future<User> me() =>
      _api.get('/me', decode: (json) => User.fromJson(asMap(json)));

  Future<GoogleCredential> googleSignIn() => _google.signIn();

  Future<void> googleSignOut() => _google.signOut();

  Future<SignInOutcome> signIn({required String idToken, Role? role}) async {
    try {
      final session = await _api.post(
        '/auth/google',
        body: {'idToken': idToken, if (role != null) 'role': role.wire},
        decode: (json) {
          final map = asMap(json);
          return (
            token: map['token'] as String,
            user: User.fromJson(asMap(map['user'])),
          );
        },
      );
      await _tokens.write(session.token);
      return SignedIn(session.user);
    } on ApiException catch (e) {
      if (e.statusCode == 422 && e.code == 'role_required') {
        return RoleRequired();
      }
      rethrow;
    }
  }

  /// Ends the local session right away. Google's own sign-out (which only
  /// makes the account picker show up again next time) can take seconds on
  /// Android, so it runs in the background and its failure is not the
  /// user's problem.
  Future<void> signOut() async {
    await _tokens.clear();
    unawaited(_google.signOut().then((_) {}, onError: (Object _) {}));
  }
}
