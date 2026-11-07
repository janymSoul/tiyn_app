import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Something that must start working before a sign-out clears the session
/// (it still needs the JWT). Must return quickly and never throw: sign-out
/// stays instant.
abstract interface class SessionEndHandler {
  Future<void> beginSignOut();
}

class NoSessionEndHandler implements SessionEndHandler {
  const NoSessionEndHandler();

  @override
  Future<void> beginSignOut() async {}
}

/// A plain holder, not a provider chain: the handler (push device cleanup)
/// depends on the signed-in user, and auth calls the handler, so wiring them
/// through providers would be a dependency loop. The handler registers itself
/// here when it starts.
class SessionEndHooks {
  SessionEndHandler handler = const NoSessionEndHandler();
}

final sessionEndHooksProvider = Provider<SessionEndHooks>(
  (_) => SessionEndHooks(),
);
