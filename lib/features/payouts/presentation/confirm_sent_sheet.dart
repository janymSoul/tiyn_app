import 'package:flutter/material.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/money/money_format.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// "I sent it" is not final until this sheet says yes. It names the amount
/// because Tiyn cannot see the transfer: the parent's word is the record.
Future<bool?> showConfirmSentSheet(BuildContext context, Money amount) {
  final l10n = AppLocalizations.of(context);
  final money = formatMoney(
    amount,
    locale: Localizations.localeOf(context).languageCode,
  );
  return showConfirmSheet(
    context,
    title: l10n.payoutConfirmSentTitle(money),
    body: l10n.payoutConfirmSentBody(money),
    yes: l10n.payoutYesSent,
    no: l10n.payoutNotYet,
  );
}

Future<bool?> showConfirmDeclineSheet(BuildContext context, Money amount) {
  final l10n = AppLocalizations.of(context);
  final money = formatMoney(
    amount,
    locale: Localizations.localeOf(context).languageCode,
  );
  return showConfirmSheet(
    context,
    title: l10n.payoutDeclineTitle(money),
    body: l10n.payoutDeclineBody,
    yes: l10n.payoutConfirmDecline,
    no: l10n.payoutKeepOpen,
    destructive: true,
  );
}

/// The safe answer is the big button; the committing one is the quiet text.
/// With [destructive] the big button is the one that keeps things as they are
/// and the warning-coloured text commits.
Future<bool?> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String body,
  required String yes,
  required String no,
  bool destructive = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: Space.s8),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Palette.muted, height: 1.5),
            ),
            const SizedBox(height: Space.s20),
            if (destructive) ...[
              FilledButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(no),
              ),
              const SizedBox(height: Space.s4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Palette.warn),
                child: Text(yes),
              ),
            ] else ...[
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(yes),
              ),
              const SizedBox(height: Space.s4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(no),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
