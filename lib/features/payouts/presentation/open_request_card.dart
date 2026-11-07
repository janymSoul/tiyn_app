import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/money/money_format.dart';
import 'package:tiyn_app/core/network/error_messages.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/app_card.dart';
import 'package:tiyn_app/design/widgets/busy_button.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/payouts/application/expiry_label.dart';
import 'package:tiyn_app/features/payouts/application/payout_problem.dart';
import 'package:tiyn_app/features/payouts/application/payout_providers.dart';
import 'package:tiyn_app/features/payouts/presentation/confirm_sent_sheet.dart';
import 'package:tiyn_app/features/payouts/presentation/expiry_text.dart';
import 'package:tiyn_app/features/teen/application/dashboard_controller.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// The teen's open cash-out request: who it waits on, the money held for it,
/// how long it has left, and Cancel behind a confirmation. Used on home (from
/// `dashboard.openPayout`) and on the payout screen.
class OpenRequestCard extends ConsumerStatefulWidget {
  const OpenRequestCard({
    super.key,
    required this.payoutId,
    required this.parentId,
    required this.amount,
    required this.expiresAt,
  });

  final String payoutId;
  final String parentId;
  final Money amount;
  final DateTime expiresAt;

  @override
  ConsumerState<OpenRequestCard> createState() => _OpenRequestCardState();
}

class _OpenRequestCardState extends ConsumerState<OpenRequestCard> {
  bool _busy = false;

  /// Refreshes through [dashboard] taken before the await: the teen may leave
  /// the screen while the call is in flight, and the card must still go.
  Future<void> _refreshEverything(DashboardController dashboard) async {
    final detail = payoutDetailProvider(widget.payoutId);
    if (mounted && ref.exists(detail)) {
      unawaited(ref.read(detail.notifier).refresh());
    }
    await dashboard.refresh();
  }

  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await _confirm();
    if (confirmed != true || !mounted) return;

    final dashboard = ref.read(dashboardControllerProvider.notifier);
    setState(() => _busy = true);
    try {
      await ref.read(payoutRepositoryProvider).cancel(widget.payoutId);
      await _refreshEverything(dashboard);
    } catch (e) {
      if (PayoutProblem.from(e) == PayoutProblem.changed) {
        // It was answered before the teen confirmed: show how it is now.
        messenger.showSnackBar(SnackBar(content: Text(l10n.payoutChanged)));
        await _refreshEverything(dashboard);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(apiErrorMessage(l10n, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirm() {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return showConfirmSheet(
      context,
      title: l10n.payoutCancelTitle,
      body: l10n.payoutCancelBody(formatMoney(widget.amount, locale: locale)),
      yes: l10n.payoutConfirmCancel,
      no: l10n.parentKeepIt,
      destructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).languageCode;
    final parent = ref.watch(familyNamesProvider)[widget.parentId];
    final left = expiryLabel(widget.expiresAt, now: DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                parent == null
                    ? l10n.payoutWaitingForParent
                    : l10n.payoutWaitingFor(parent),
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: Space.s8),
            Text(
              l10n.payoutHeld(formatMoney(widget.amount, locale: locale)),
              style: text.bodyLarge,
            ),
            const SizedBox(height: Space.s4),
            Text(
              expiryText(l10n, left),
              style: text.bodyMedium?.copyWith(color: Palette.muted),
            ),
            const SizedBox(height: Space.s16),
            BusyButton(
              outlined: true,
              busy: _busy,
              onPressed: _cancel,
              child: Text(l10n.payoutCancelRequest),
            ),
          ],
        ),
      ),
    );
  }
}
