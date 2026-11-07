import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiyn_app/app/app.dart';
import 'package:tiyn_app/app/config.dart';
import 'package:tiyn_app/core/bank/bank_providers.dart';
import 'package:tiyn_app/core/bank/method_channel_bank_launcher.dart';
import 'package:tiyn_app/core/push/firebase_init.dart';
import 'package:tiyn_app/core/push/firebase_push_messaging.dart';
import 'package:tiyn_app/core/push/notification_settings_opener.dart';
import 'package:tiyn_app/core/push/push_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  final config = AppConfig.fromEnvironment();
  final firebaseReady = await initFirebase();
  runApp(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        appConfigProvider.overrideWithValue(config),
        bankLauncherProvider.overrideWithValue(
          const MethodChannelBankLauncher(),
        ),
        notificationSettingsOpenerProvider.overrideWithValue(
          const MethodChannelNotificationSettingsOpener(),
        ),
        pushMessagingProvider.overrideWithValue(
          FirebasePushMessaging(initialized: firebaseReady),
        ),
      ],
      child: const TiynApp(),
    ),
  );
}
