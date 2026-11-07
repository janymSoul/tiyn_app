import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/core/push/no_push_messaging.dart';
import 'package:tiyn_app/core/push/push_messaging.dart';

/// Off by default so tests never touch Firebase; `main` overrides it with the
/// real service.
final pushMessagingProvider = Provider<PushMessaging>(
  (_) => const NoPushMessaging(),
);
