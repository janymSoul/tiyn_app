import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/core/push/push_messaging.dart';
import 'package:tiyn_app/core/push/push_providers.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/push/application/device_registration.dart';
import 'package:tiyn_app/features/push/data/push_store.dart';

/// What the permission UI needs to decide. Nothing is shown until [loaded].
@immutable
class PushPrompt {
  const PushPrompt({
    this.loaded = false,
    this.permission,
    this.explained = false,
    this.deniedDismissed = false,
  });

  final bool loaded;
  final PushPermission? permission;

  /// We already showed our explanation to this user.
  final bool explained;
  final bool deniedDismissed;

  /// Never asked, so our explanation (then the system dialog) may be shown.
  bool get shouldAsk =>
      loaded && permission == PushPermission.notDetermined && !explained;

  /// The system said no after we asked, and the card is not dismissed.
  bool get showDeniedCard =>
      loaded &&
      permission == PushPermission.denied &&
      explained &&
      !deniedDismissed;

  PushPrompt copyWith({
    PushPermission? permission,
    bool? explained,
    bool? deniedDismissed,
  }) => PushPrompt(
    loaded: loaded,
    permission: permission ?? this.permission,
    explained: explained ?? this.explained,
    deniedDismissed: deniedDismissed ?? this.deniedDismissed,
  );
}

/// The notification permission and the one-time prompts around it. Older
/// Android grants it at install, so there the status is `granted` and nothing
/// is ever shown.
class PushPromptController extends Notifier<PushPrompt> {
  @override
  PushPrompt build() {
    final userId = ref.watch(currentUserIdProvider);
    final lifecycle = AppLifecycleListener(
      onResume: () => unawaited(refreshPermission()),
    );
    ref.onDispose(lifecycle.dispose);
    if (userId != null) unawaited(_load(userId));
    return const PushPrompt();
  }

  PushStore get _store => ref.read(pushStoreProvider);

  Future<void> _load(String userId) async {
    final permission = await ref.read(pushMessagingProvider).permissionStatus();
    final explained = await _store.readFlag(userId, PromptFlag.explained);
    final dismissed = await _store.readFlag(
      userId,
      PromptFlag.deniedCardDismissed,
    );
    if (!ref.mounted) return;
    state = PushPrompt(
      loaded: true,
      permission: permission,
      explained: explained,
      deniedDismissed: dismissed,
    );
  }

  /// The user may have changed it in the system settings.
  Future<void> refreshPermission() async {
    if (!state.loaded) return;
    final permission = await ref.read(pushMessagingProvider).permissionStatus();
    if (!ref.mounted) return;
    state = state.copyWith(permission: permission);
  }

  Future<void> markExplained() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    state = state.copyWith(explained: true);
    await _store.writeFlag(userId, PromptFlag.explained);
  }

  /// "Turn on": the system dialog, after our own explanation.
  Future<PushPermission> turnOn() async {
    await markExplained();
    final permission = await ref
        .read(pushMessagingProvider)
        .requestPermission();
    if (ref.mounted) state = state.copyWith(permission: permission);
    return permission;
  }

  Future<void> dismissDeniedCard() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    state = state.copyWith(deniedDismissed: true);
    await _store.writeFlag(userId, PromptFlag.deniedCardDismissed);
  }
}

final pushPromptProvider = NotifierProvider<PushPromptController, PushPrompt>(
  PushPromptController.new,
);
