import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/core/push/push_messaging.dart';
import 'package:tiyn_app/core/push/push_payload.dart';
import 'package:tiyn_app/core/push/push_providers.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/push/application/push_refresh.dart';

/// The one banner on screen. [id] is new for every push, so a banner that
/// replaces another restarts its auto-dismiss.
@immutable
class PushBannerData {
  const PushBannerData({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final PushPayload payload;
}

/// Handles pushes that arrive while the app is open (Android does not show
/// them): refreshes what they made stale and shows at most one banner.
class PushBannerController extends Notifier<PushBannerData?> {
  int _next = 0;

  @override
  PushBannerData? build() {
    final sub = ref
        .watch(pushMessagingProvider)
        .onForegroundMessage
        .listen(_onMessage, onError: (Object _) {});
    ref.onDispose(() => unawaited(sub.cancel()));
    return null;
  }

  void _onMessage(PushMessage message) {
    // No session: this push cannot be for the person using the phone now.
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    final payload = message.payload;
    ref.read(pushRefresherProvider).apply(payload, user.role);

    final title = message.title?.trim() ?? '';
    final body = message.body?.trim() ?? '';
    if (title.isEmpty && body.isEmpty) return;
    state = PushBannerData(
      id: _next++,
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Ignored when a newer banner has already replaced [id].
  void dismiss(int id) {
    if (state?.id == id) state = null;
  }
}

final pushBannerProvider =
    NotifierProvider<PushBannerController, PushBannerData?>(
      PushBannerController.new,
    );
