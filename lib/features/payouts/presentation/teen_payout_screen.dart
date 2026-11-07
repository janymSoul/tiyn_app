import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiyn_app/core/lifecycle/refresh_on_foreground.dart';
import 'package:tiyn_app/core/money/money_format.dart';
import 'package:tiyn_app/core/network/error_messages.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/error_card.dart';
import 'package:tiyn_app/features/payouts/application/payout_problem.dart';
import 'package:tiyn_app/features/payouts/application/payout_providers.dart';
import 'package:tiyn_app/features/payouts/data/cancel_reason.dart';
import 'package:tiyn_app/features/payouts/data/payout.dart';
import 'package:tiyn_app/features/payouts/data/payout_state.dart';
import 'package:tiyn_app/features/payouts/presentation/open_request_card.dart';
import 'package:tiyn_app/features/payouts/presentation/payout_message.dart';
import 'package:tiyn_app/features/teen/application/dashboard_controller.dart';
import 'package:tiyn_app/features/teen/presentation/teen_home_screen.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// One payout as the teen sees it: the open request with Cancel, or how it
/// ended. Where a `PAYOUT_*` push lands. It is not a history: one payout.
class TeenPayoutScreen extends ConsumerWidget {
  const TeenPayoutScreen({super.key, required this.payoutId});

  final String payoutId;

  Future<void> _refresh(WidgetRef ref) async {
    unawaited(ref.read(dashboardControllerProvider.notifier).refresh());
    await ref.read(payoutDetailProvider(payoutId).notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final payout = ref.watch(payoutDetailProvider(payoutId));

    return RefreshOnForeground(
      tab: TeenTab.home,
      onRefresh: () => unawaited(_refresh(ref)),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Palette.background,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: payout.when(
              skipLoadingOnReload: true,
              loading: () => ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
              error: (e, _) {
                final problem = PayoutProblem.from(e);
                if (problem == PayoutProblem.notFound ||
                    problem == PayoutProblem.notLinked) {
                  return PayoutMessage(title: l10n.payoutUnavailable);
                }
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    ErrorCard(
                      message: apiErrorMessage(l10n, e),
                      onRetry: () =>
                          ref.invalidate(payoutDetailProvider(payoutId)),
                    ),
                  ],
                );
              },
              data: (p) => _Body(payout: p),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.payout});

  final Payout payout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final amount = formatMoney(payout.amount, locale: locale);

    return switch (payout.state) {
      PayoutState.requested => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          OpenRequestCard(
            payoutId: payout.id,
            parentId: payout.parentId,
            amount: payout.amount,
            // An open payout always carries it; Payout.fromJson enforces that.
            expiresAt: payout.expiresAt!,
          ),
        ],
      ),
      PayoutState.fulfilled => PayoutMessage(
        title: l10n.payoutFulfilledTitle(amount),
        body: l10n.payoutFulfilledBody,
      ),
      PayoutState.cancelled => switch (payout.cancelReason) {
        CancelReason.declined => PayoutMessage(
          title: l10n.payoutDeclinedTitle,
          body: l10n.payoutDeclinedBody(amount),
        ),
        CancelReason.expired => PayoutMessage(
          title: l10n.payoutExpiredTitle,
          body: l10n.payoutExpiredBody(amount),
        ),
        CancelReason.unlinked => PayoutMessage(
          title: l10n.payoutUnlinkedTitle,
          body: l10n.payoutUnlinkedBody(amount),
        ),
        CancelReason.teenCancelled || null => PayoutMessage(
          title: l10n.payoutCancelledTitle,
          body: l10n.payoutCancelledBody(amount),
        ),
      },
    };
  }
}
