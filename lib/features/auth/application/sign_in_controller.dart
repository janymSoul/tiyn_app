import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/auth_repository.dart';
import 'package:tiyn_app/features/auth/data/google_identity.dart';

sealed class SignInState {}

final class Welcome extends SignInState {
  Welcome({this.error});

  final Object? error;
}

final class Authenticating extends SignInState {}

final class ChoosingRole extends SignInState {
  ChoosingRole({
    required this.credential,
    this.selected,
    this.sending = false,
    this.error,
  });

  final GoogleCredential credential;
  final Role? selected;
  final bool sending;
  final Object? error;
}

/// The Google ID token was rejected while the user was choosing a role.
final class SignInExpired implements Exception {
  const SignInExpired();
}

class SignInController extends Notifier<SignInState> {
  @override
  SignInState build() => Welcome();

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> continueWithGoogle() async {
    if (state is Authenticating) return;
    state = Authenticating();
    try {
      final credential = await _repository.googleSignIn();
      final outcome = await _repository.signIn(idToken: credential.idToken);
      switch (outcome) {
        case SignedIn(:final user):
          ref.read(authControllerProvider.notifier).signedIn(user);
        case RoleRequired():
          state = ChoosingRole(credential: credential);
      }
    } on GoogleSignInException catch (e) {
      state = e.code == GoogleSignInExceptionCode.canceled
          ? Welcome()
          : Welcome(error: e);
    } on Object catch (e) {
      state = Welcome(error: e);
    }
  }

  void selectRole(Role role) {
    final current = state;
    if (current is! ChoosingRole || current.sending) return;
    state = ChoosingRole(credential: current.credential, selected: role);
  }

  Future<void> confirmRole() async {
    final current = state;
    if (current is! ChoosingRole || current.sending) return;
    final role = current.selected;
    if (role == null) return;

    state = ChoosingRole(
      credential: current.credential,
      selected: role,
      sending: true,
    );
    try {
      final outcome = await _repository.signIn(
        idToken: current.credential.idToken,
        role: role,
      );
      switch (outcome) {
        case SignedIn(:final user):
          ref.read(authControllerProvider.notifier).signedIn(user);
        case RoleRequired():
          state = ChoosingRole(
            credential: current.credential,
            selected: role,
            error: const ApiException(code: 'role_required', statusCode: 422),
          );
      }
    } on ApiException catch (e) {
      if (e.code == 'invalid_identity') {
        await _googleSignOutQuietly();
        state = Welcome(error: const SignInExpired());
      } else {
        state = ChoosingRole(
          credential: current.credential,
          selected: role,
          error: e,
        );
      }
    } on Object catch (e) {
      state = ChoosingRole(
        credential: current.credential,
        selected: role,
        error: e,
      );
    }
  }

  Future<void> useAnotherAccount() async {
    await _googleSignOutQuietly();
    state = Welcome();
  }

  Future<void> _googleSignOutQuietly() async {
    try {
      await _repository.googleSignOut();
    } on Object {
      // Local sign-out is best effort; the user is back on the welcome step either way.
    }
  }
}

final signInControllerProvider =
    NotifierProvider.autoDispose<SignInController, SignInState>(
      SignInController.new,
    );
