import 'dart:ui';

/// The one rule for which language the app speaks: Kazakh follows the device,
/// everything else is Russian. The push registration sends the same choice so
/// the notification text matches the screen.
Locale resolveAppLocale(Locale? device) =>
    device?.languageCode == 'kk' ? const Locale('kk') : const Locale('ru');

/// The backend's `locale` field: `kk` or `ru`.
String pushLocale(Locale? device) => resolveAppLocale(device).languageCode;
