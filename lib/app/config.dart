import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/core/money/money.dart';

/// The smallest payout the backend accepts by default (`LEDGER_MIN_PAYOUT_AMOUNT`,
/// 100 KZT). The API does not expose it, so this is only for the inline hint
/// and the disabled button; the server's 422 `amount_too_small` is the truth.
const kMinPayout = Money.kzt(10000);

enum Flavor { dev, staging, prod }

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.apiBaseUrl,
    required this.googleServerClientId,
  });

  factory AppConfig.fromEnvironment() {
    const flavorName = String.fromEnvironment('FLAVOR');
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const googleServerClientId = String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
    );

    final flavor = Flavor.values.where((f) => f.name == flavorName).firstOrNull;
    final baseUri = Uri.tryParse(apiBaseUrl);
    final validBaseUri =
        baseUri != null && baseUri.hasScheme && baseUri.host.isNotEmpty;
    if (flavor == null || !validBaseUri) {
      throw StateError(
        'Missing or invalid FLAVOR / API_BASE_URL. Run with e.g. '
        '`flutter run --flavor dev --dart-define-from-file=env/dev.json`.',
      );
    }
    return AppConfig(
      flavor: flavor,
      apiBaseUrl: baseUri,
      googleServerClientId: googleServerClientId.isEmpty
          ? null
          : googleServerClientId,
    );
  }

  final Flavor flavor;
  final Uri apiBaseUrl;
  final String? googleServerClientId;
}

final appConfigProvider = Provider<AppConfig>(
  (_) => throw UnimplementedError('appConfigProvider must be overridden'),
);
