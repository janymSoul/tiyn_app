import 'package:flutter/foundation.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// Plain-language message for [error]. Internal error codes are for
/// developers: they are appended only when [showCode] is true, which defaults
/// to debug builds.
String apiErrorMessage(
  AppLocalizations l10n,
  Object error, {
  bool showCode = kDebugMode,
}) {
  if (error is! ApiException) return l10n.errorUnknown;
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
    'invalid_title' => l10n.errorInvalidTitle,
    'invalid_reward' => l10n.errorInvalidReward,
    'invalid_penalty' => l10n.errorInvalidPenalty,
    'invalid_deadline' => l10n.errorInvalidDeadline,
    'invalid_milestone' => l10n.errorInvalidMilestone,
    'teen_required' => l10n.errorTeenRequired,
    'deadline_passed' => l10n.errorDeadlinePassed,
    'unsupported_proof' => l10n.errorUnsupportedProof,
    'payload_too_large' => l10n.errorPayloadTooLarge,
    'invalid_transition' || 'concurrent_modification' => l10n.errorTaskChanged,
    'invalid_idempotency_key' => l10n.errorInvalidIdempotencyKey,
    _ => showCode ? '${l10n.errorUnknown} (${error.code})' : l10n.errorUnknown,
  };
}
