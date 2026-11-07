import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tiyn_app/app/router/routes.dart';
import 'package:tiyn_app/core/money/money_format.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/features/payouts/application/cash_out_rule.dart';
import 'package:tiyn_app/features/teen/data/dashboard.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// Why the teen cannot cash out, in words. Null when they can.
String? cashOutExplanation(
  AppLocalizations l10n,
  CashOutState state,
  String locale,
) => switch (state) {
  CashOutAllowed() => null,
  CashOutOpenRequest() => l10n.errPayoutAlreadyOpen,
  CashOutInDebt(:final owed) => l10n.cashOutDebt(
    formatMoney(owed, locale: locale),
  ),
  CashOutBelowMinimum(:final minimum, :final hasLocked) => [
    l10n.cashOutBelowMin(formatMoney(minimum, locale: locale)),
    if (hasLocked) l10n.cashOutLockedNote,
  ].join(' '),
};

/// The "Cash out" button on the teen home, or the reason it is disabled. With
/// an open request it shows nothing: the request card takes its place.
class CashOutSection extends StatelessWidget {
  const CashOutSection({super.key, required this.dashboard});

  final Dashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final state = cashOutState(
      dashboard.balance,
      hasOpenRequest: dashboard.openPayout != null,
    );
    if (state is CashOutOpenRequest) return const SizedBox.shrink();

    final why = cashOutExplanation(l10n, state, locale);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s16),
      child: Column(
        children: [
          FilledButton(
            onPressed: why == null
                ? () => context.push(Routes.teenCashOut)
                : null,
            child: Text(l10n.payoutCashOut),
          ),
          if (why != null) ...[
            const SizedBox(height: Space.s8),
            Text(
              why,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Palette.muted, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
