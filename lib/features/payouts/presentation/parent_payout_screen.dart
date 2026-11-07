import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiyn_app/core/bank/bank.dart';
import 'package:tiyn_app/core/bank/bank_launcher.dart';
import 'package:tiyn_app/core/bank/bank_providers.dart';
import 'package:tiyn_app/core/lifecycle/refresh_on_foreground.dart';
import 'package:tiyn_app/core/money/money_format.dart';
import 'package:tiyn_app/core/network/error_messages.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/busy_button.dart';
import 'package:tiyn_app/design/widgets/error_card.dart';
import 'package:tiyn_app/design/widgets/info_banner.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/parent/application/parent_tabs.dart';
import 'package:tiyn_app/features/payouts/application/expiry_label.dart';
import 'package:tiyn_app/features/payouts/application/payout_copy_text.dart';
import 'package:tiyn_app/features/payouts/application/payout_problem.dart';
import 'package:tiyn_app/features/payouts/application/payout_providers.dart';
import 'package:tiyn_app/features/payouts/data/cancel_reason.dart';
import 'package:tiyn_app/features/payouts/data/payout.dart';
import 'package:tiyn_app/features/payouts/data/payout_state.dart';
import 'package:tiyn_app/features/payouts/presentation/confirm_sent_sheet.dart';
import 'package:tiyn_app/features/payouts/presentation/expiry_text.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// A teen's cash-out request as the parent sees it: send the money, then
/// confirm. Nothing here marks the payout fulfilled except the confirmation
/// sheet's "Yes, I sent it"; opening a bank app never does.
class ParentPayoutScreen extends ConsumerStatefulWidget {
  const ParentPayoutScreen({super.key, required this.payoutId});

  final String payoutId;

  @override
  ConsumerState<ParentPayoutScreen> createState() => _ParentPayoutScreenState();
}

enum _Busy { none, fulfil, decline }

class _ParentPayoutScreenState extends ConsumerState<ParentPayoutScreen> {
  _Busy _busy = _Busy.none;

  /// `insufficient_funds` on fulfil: the teen's balance no longer covers it.
  bool _noCover = false;

  /// The link is gone (403 on an action).
  bool _notLinked = false;

  /// A fulfil that may or may not have landed. The confirmation was already
  /// given, so "Try again" resends without asking again. Safe on the server:
  /// fulfilling a fulfilled payout writes no second debit.
  String? _fulfilUnsure;

  /// What happened when a bank was opened, if it did not simply open.
  String? _bankNote;

  Future<void> _refresh() =>
      ref.read(payoutDetailProvider(widget.payoutId).notifier).refresh();

  Future<void> _fulfil(Payout payout) async {
    if (_fulfilUnsure == null) {
      final yes = await showConfirmSentSheet(context, payout.amount);
      if (yes != true || !mounted) return;
    }
    await _act(
      busy: _Busy.fulfil,
      call: () => ref.read(payoutRepositoryProvider).fulfil(payout.id),
      doneText: AppLocalizations.of(context).payoutSentDone,
    );
  }

  Future<void> _decline(Payout payout) async {
    final yes = await showConfirmDeclineSheet(context, payout.amount);
    if (yes != true || !mounted) return;
    await _act(
      busy: _Busy.decline,
      call: () => ref.read(payoutRepositoryProvider).decline(payout.id),
      doneText: AppLocalizations.of(context).payoutDeclinedDone,
    );
  }

  Future<void> _act({
    required _Busy busy,
    required Future<Payout> Function() call,
    required String doneText,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    // Taken before the await: the parent may press Back while the call is in
    // flight, and the list and badge must still hear about the outcome.
    final requests = ref.read(requestedPayoutsProvider.notifier);
    setState(() {
      _busy = busy;
      _fulfilUnsure = null;
    });
    try {
      await call();
      unawaited(requests.refresh());
      if (mounted) router.pop();
      messenger.showSnackBar(SnackBar(content: Text(doneText)));
    } catch (e) {
      final problem = PayoutProblem.from(e);
      if (problem != PayoutProblem.insufficientFunds &&
          problem != PayoutProblem.other) {
        // Changed, unlinked or unsure: the list may be stale either way.
        unawaited(requests.refresh());
      }
      if (!mounted) return;
      switch (problem) {
        case PayoutProblem.insufficientFunds:
          setState(() => _noCover = true);
        case PayoutProblem.changed:
          // Answered or cancelled meanwhile: show how it ended.
          messenger.showSnackBar(SnackBar(content: Text(l10n.payoutChanged)));
          await _refresh();
        case PayoutProblem.notLinked:
          setState(() => _notLinked = true);
        case PayoutProblem.ambiguous when busy == _Busy.fulfil:
          // Maybe it went through: look before asking again.
          await _refresh();
          if (mounted) setState(() => _fulfilUnsure = apiErrorMessage(l10n, e));
        default:
          messenger.showSnackBar(
            SnackBar(content: Text(apiErrorMessage(l10n, e))),
          );
      }
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  /// Opens a bank app and nothing else. Whether the money was sent is the
  /// parent's word, given later in the confirmation sheet; this never calls
  /// fulfil, whatever the result.
  Future<void> _openBank(Bank bank) async {
    final l10n = AppLocalizations.of(context);
    final result = await ref.read(bankLauncherProvider).open(bank);
    if (!mounted) return;
    setState(() {
      _bankNote = switch (result) {
        BankLaunchResult.opened => null,
        BankLaunchResult.storeOpened => l10n.payoutBankStore(bank.displayName),
        BankLaunchResult.unavailable => l10n.payoutBankUnavailable(
          bank.displayName,
        ),
      };
    });
  }

  Future<void> _copy(Payout payout) async {
    final messenger = ScaffoldMessenger.of(context);
    final text = AppLocalizations.of(context).payoutCopied;
    await Clipboard.setData(ClipboardData(text: payoutCopyText(payout.amount)));
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final payout = ref.watch(payoutDetailProvider(widget.payoutId));

    return RefreshOnForeground(
      tab: ParentTab.review,
      onRefresh: () => unawaited(_refresh()),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Palette.background,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
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
                  return _Message(title: l10n.payoutUnavailable);
                }
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    ErrorCard(
                      message: apiErrorMessage(l10n, e),
                      onRetry: () =>
                          ref.invalidate(payoutDetailProvider(widget.payoutId)),
                    ),
                  ],
                );
              },
              data: (p) => p.state == PayoutState.requested
                  ? _open(context, p)
                  : _outcome(context, p),
            ),
          ),
        ),
      ),
    );
  }

  Widget _open(BuildContext context, Payout payout) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).languageCode;
    final name = ref.watch(familyNamesProvider)[payout.teenId];
    final amount = formatMoney(payout.amount, locale: locale);
    final working = _busy != _Busy.none;

    if (_notLinked) return _Message(title: l10n.payoutParentUnlinked);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        Semantics(
          header: true,
          child: Text(
            name == null ? l10n.payoutRowTitle : l10n.payoutAsksForTitle(name),
            style: text.titleMedium?.copyWith(color: Palette.muted),
          ),
        ),
        const SizedBox(height: Space.s4),
        Text(
          amount,
          style: text.displaySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: Space.s4),
        Text(
          expiryText(l10n, expiryLabel(payout.expiresAt!, now: DateTime.now())),
          style: text.bodyMedium?.copyWith(color: Palette.muted),
        ),
        const SizedBox(height: Space.s24),
        if (_noCover) ...[
          InfoBanner(l10n.payoutNoCover(amount)),
          const SizedBox(height: Space.s16),
        ] else ...[
          Semantics(
            header: true,
            child: Text(
              l10n.payoutStepSend,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: Space.s8),
          Text(
            l10n.payoutSendHint(amount),
            style: text.bodyMedium?.copyWith(color: Palette.muted, height: 1.5),
          ),
          const SizedBox(height: Space.s12),
          for (final bank in ref.watch(banksProvider)) ...[
            FilledButton.tonal(
              onPressed: working ? null : () => _openBank(bank),
              child: Text(l10n.payoutOpenBank(bank.displayName)),
            ),
            const SizedBox(height: Space.s8),
          ],
          if (_bankNote != null) ...[
            InfoBanner(_bankNote!),
            const SizedBox(height: Space.s8),
          ],
          OutlinedButton.icon(
            onPressed: () => _copy(payout),
            icon: const Icon(Icons.copy, size: 18),
            label: Text(l10n.payoutCopyAmount),
          ),
          const SizedBox(height: Space.s24),
          Semantics(
            header: true,
            child: Text(
              l10n.payoutStepConfirm,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: Space.s12),
          if (_fulfilUnsure != null) ...[
            Text(
              _fulfilUnsure!,
              style: text.bodyMedium?.copyWith(
                color: Palette.warn,
                height: 1.5,
              ),
            ),
            const SizedBox(height: Space.s12),
          ],
          BusyButton(
            busy: _busy == _Busy.fulfil,
            onPressed: working ? null : () => _fulfil(payout),
            child: Text(
              _fulfilUnsure != null ? l10n.actionTryAgain : l10n.payoutISentIt,
            ),
          ),
          const SizedBox(height: Space.s8),
        ],
        BusyButton(
          outlined: true,
          busy: _busy == _Busy.decline,
          onPressed: working ? null : () => _decline(payout),
          child: Text(l10n.payoutDecline),
        ),
      ],
    );
  }

  Widget _outcome(BuildContext context, Payout payout) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final amount = formatMoney(payout.amount, locale: locale);
    return switch (payout.state) {
      PayoutState.fulfilled => _Message(
        title: l10n.payoutParentFulfilledTitle,
        body: l10n.payoutParentFulfilledBody(amount),
      ),
      _ => _Message(
        title: switch (payout.cancelReason) {
          CancelReason.declined => l10n.payoutParentDeclined,
          CancelReason.expired => l10n.payoutParentExpired,
          CancelReason.unlinked => l10n.payoutParentUnlinked,
          CancelReason.teenCancelled || null => l10n.payoutParentTeenCancelled,
        },
      ),
    };
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: Space.s12),
          Text(
            body!,
            style: text.bodyLarge?.copyWith(color: Palette.muted, height: 1.5),
          ),
        ],
      ],
    );
  }
}
