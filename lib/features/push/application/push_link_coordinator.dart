import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/app/router/router.dart';
import 'package:tiyn_app/core/push/push_payload.dart';
import 'package:tiyn_app/core/push/push_providers.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/push/application/push_location.dart';

/// Turns a tapped notification into navigation.
///
/// A tap (from the background or from a closed app) is held until the session
/// is known, then applied once. With no session it is dropped: nobody is
/// signed in to open it. The router's redirect still has the last word, so a
/// teen with no family lands on the join screen whatever was tapped.
class PushLinkCoordinator {
  PushLinkCoordinator(this._ref) {
    final push = _ref.read(pushMessagingProvider);
    final sub = push.onOpenedMessage.listen(
      (m) => _hold(m.payload),
      onError: (Object _) {},
    );
    _ref.onDispose(() => unawaited(sub.cancel()));
    unawaited(
      push.initialMessage().then(
        (m) {
          if (m != null) _hold(m.payload);
        },
        onError: (Object e) => debugPrint('No initial push: ${e.runtimeType}'),
      ),
    );
    _ref.listen(authControllerProvider, (_, _) => _tryApply());
    _ref.listen(familyControllerProvider, (_, _) => _tryApply());
  }

  final Ref _ref;
  PushPayload? _pending;

  void _hold(PushPayload payload) {
    _pending = payload;
    _tryApply();
  }

  void _tryApply() {
    final payload = _pending;
    if (payload == null) return;

    final auth = _ref.read(authControllerProvider);
    final authPending = (auth.isLoading && !auth.hasValue) || auth.hasError;
    if (authPending) return;

    final user = auth.value;
    if (user == null) {
      _pending = null;
      return;
    }

    if (user.role == Role.teen) {
      final family = _ref.read(familyControllerProvider);
      if (family.isLoading || family.hasError) return;
    }

    _pending = null;
    _ref.read(routerProvider).go(pushLocation(payload, user.role));
  }
}

final pushLinkCoordinatorProvider = Provider<PushLinkCoordinator>(
  PushLinkCoordinator.new,
);
