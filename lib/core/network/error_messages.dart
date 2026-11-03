import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

String apiErrorMessage(AppLocalizations l10n, Object error) {
  if (error is! ApiException) return l10n.errorUnknown('unknown_error');
  return switch (error.code) {
    'network_error' => l10n.errorNoConnection,
    'timeout' => l10n.errorTimeout,
    'unauthenticated' => l10n.errorUnauthenticated,
    'forbidden' => l10n.errorForbidden,
    'internal_error' => l10n.errorServer,
    'invalid_identity' => l10n.errorInvalidIdentity,
    'identity_provider_unavailable' => l10n.errorIdentityUnavailable,
    'invalid_join_code' => l10n.errorInvalidJoinCode,
    'conflict' => l10n.errorConflict,
    _ => l10n.errorUnknown(error.code),
  };
}
