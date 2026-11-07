import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/app/router/router.dart';
import 'package:tiyn_app/core/l10n/app_locale.dart';
import 'package:tiyn_app/design/theme.dart';
import 'package:tiyn_app/features/push/application/device_registration.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

class TiynApp extends ConsumerWidget {
  const TiynApp({super.key, this.locale});

  /// Forces a locale (tests, dev). When null, ru/kk follow the device and everything else falls back to Russian.
  final Locale? locale;

  static Locale _resolve(Locale? device, Iterable<Locale> supported) =>
      resolveAppLocale(device);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(deviceRegistrationProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: buildTheme(),
      routerConfig: ref.watch(routerProvider),
      locale: locale,
      supportedLocales: const [Locale('ru'), Locale('kk'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: locale == null ? _resolve : null,
    );
  }
}
