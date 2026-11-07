import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiyn_app/app/router/routes.dart';
import 'package:tiyn_app/core/network/error_messages.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/app_card.dart';
import 'package:tiyn_app/design/widgets/error_card.dart';
import 'package:tiyn_app/design/widgets/money_text.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/payouts/application/expiry_label.dart';
import 'package:tiyn_app/features/payouts/application/payout_providers.dart';
import 'package:tiyn_app/features/payouts/data/payout.dart';
import 'package:tiyn_app/features/payouts/presentation/expiry_text.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// Whether the section shows anything at all. While it is empty the To check
/// tab looks exactly as it did before payouts.
bool payoutSectionVisible(AsyncValue<List<Payout>> requests) =>
    requests.isLoading ||
    requests.hasError ||
    (requests.value?.isNotEmpty ?? false);

/// "Payout requests": the teens' open cash-out requests addressed to this
/// parent, oldest first, above the proofs. It loads and fails on its own, so a
/// failing list never blanks the proofs below it.
class PayoutRequestsSection extends ConsumerWidget {
  const PayoutRequestsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final requests = ref.watch(requestedPayoutsProvider);
    final names = ref.watch(familyNamesProvider);

    return requests.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: Space.s24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.only(bottom: Space.s16),
        child: ErrorCard(
          message: apiErrorMessage(l10n, e),
          onRetry: () => ref.invalidate(requestedPayoutsProvider),
        ),
      ),
      data: (payouts) {
        if (payouts.isEmpty) return const SizedBox.shrink();
        final now = DateTime.now();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s8),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.payoutSectionTitle(payouts.length),
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            for (final payout in payoutQueue(payouts))
              Padding(
                padding: const EdgeInsets.only(bottom: Space.s8),
                child: AppCard(
                  onTap: () => context.push(Routes.parentPayout(payout.id)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              names[payout.teenId] ?? '',
                              style: text.bodySmall?.copyWith(
                                color: Palette.muted,
                              ),
                            ),
                            const SizedBox(height: Space.s4),
                            Text(
                              l10n.payoutRowTitle,
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: Space.s4),
                            Text(
                              expiryText(
                                l10n,
                                expiryLabel(payout.expiresAt!, now: now),
                              ),
                              style: text.bodySmall?.copyWith(
                                color: Palette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Space.s12),
                      MoneyText(
                        payout.amount,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: Space.s8),
          ],
        );
      },
    );
  }
}
