import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiyn_app/app/config.dart';
import 'package:tiyn_app/core/money/money_format.dart';
import 'package:tiyn_app/core/network/error_messages.dart';
import 'package:tiyn_app/core/network/idempotent_submit_controller.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/busy_button.dart';
import 'package:tiyn_app/design/widgets/error_card.dart';
import 'package:tiyn_app/design/widgets/info_banner.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';
import 'package:tiyn_app/features/payouts/application/cash_out_rule.dart';
import 'package:tiyn_app/features/payouts/application/payout_amount.dart';
import 'package:tiyn_app/features/payouts/application/payout_problem.dart';
import 'package:tiyn_app/features/payouts/application/payout_providers.dart';
import 'package:tiyn_app/features/payouts/application/request_payout_controller.dart';
import 'package:tiyn_app/features/payouts/presentation/cash_out_section.dart';
import 'package:tiyn_app/features/teen/application/dashboard_controller.dart';
import 'package:tiyn_app/features/teen/data/dashboard.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// The teen asks a linked parent for money. Full-screen form, opened from the
/// "Cash out" button on home.
class RequestPayoutScreen extends ConsumerStatefulWidget {
  const RequestPayoutScreen({super.key});

  @override
  ConsumerState<RequestPayoutScreen> createState() =>
      _RequestPayoutScreenState();
}

class _RequestPayoutScreenState extends ConsumerState<RequestPayoutScreen> {
  final _amount = TextEditingController();
  late final RequestPayoutController _request;

  String? _chosenParentId;
  String? _amountServerError;
  String? _formError;

  /// A 409 `payout_already_open`: nothing more can be done here.
  bool _alreadyOpen = false;

  /// The request went through; the form is on its way out.
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _request = RequestPayoutController(
      send: (r, key) => ref
          .read(payoutRepositoryProvider)
          .create(parentId: r.parentId, amount: r.amount, key: key),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _request.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _edited() {
    _request.noteEdited();
    setState(() {
      _amountServerError = null;
      if (!_alreadyOpen) _formError = null;
    });
  }

  Future<void> _refreshDashboard() =>
      ref.read(dashboardControllerProvider.notifier).refresh();

  Future<void> _submit(List<FamilyMember> parents, Dashboard dashboard) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final PayoutRequest request;
    final pending = _request.pending;
    if (_request.phase == SubmitPhase.ambiguous && pending != null) {
      request = pending; // resend exactly what the server may have seen
    } else {
      final amount = validatePayoutAmount(
        _amount.text,
        available: dashboard.balance.available,
      ).amount;
      final parentId = _parentId(parents);
      if (amount == null || parentId == null) return;
      request = PayoutRequest(parentId: parentId, amount: amount);
    }

    final ok = await _request.submit(request);
    if (!mounted) return;
    if (ok) {
      setState(() => _done = true);
      final name = parents
          .where((p) => p.id == request.parentId)
          .map((p) => p.displayName)
          .firstOrNull;
      await _refreshDashboard();
      if (!mounted) return;
      router.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.payoutSent(name ?? ''))),
      );
      return;
    }
    final error = _request.error;
    if (_request.phase == SubmitPhase.rejected && error != null) {
      _showRejection(l10n, error);
    }
  }

  void _showRejection(AppLocalizations l10n, Object error) {
    final problem = PayoutProblem.from(error);
    setState(() {
      switch (problem) {
        case PayoutProblem.amountTooSmall:
          _amountServerError = l10n.errPayoutTooSmall;
        case PayoutProblem.insufficientFunds:
          _amountServerError = l10n.errPayoutInsufficient;
        case PayoutProblem.invalidAmount:
          _amountServerError = l10n.errPayoutAmountPositive;
        case PayoutProblem.parentRequired:
          _formError = l10n.errPayoutChooseParent;
        case PayoutProblem.alreadyOpen:
          _alreadyOpen = true;
          _formError = l10n.errPayoutAlreadyOpen;
        case PayoutProblem.notLinked:
          _formError = l10n.errPayoutNotLinked;
        default:
          _formError = apiErrorMessage(l10n, error);
      }
    });
    switch (problem) {
      case PayoutProblem.insufficientFunds || PayoutProblem.alreadyOpen:
        // What the teen has changed under us: show the new numbers.
        unawaited(_refreshDashboard());
      case PayoutProblem.notLinked:
        unawaited(ref.read(familyControllerProvider.notifier).refresh());
      default:
    }
  }

  Future<void> _confirmEdit() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.createEditWarnTitle),
        content: Text(l10n.payoutEditWarnBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.createEditAnyway),
          ),
        ],
      ),
    );
    if (ok ?? false) _request.unlockToEdit();
  }

  /// The one parent, or the one the teen picked. Never a default among several.
  String? _parentId(List<FamilyMember> parents) {
    if (parents.length == 1) return parents.single.id;
    return parents.any((p) => p.id == _chosenParentId) ? _chosenParentId : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final dashboard = ref.watch(dashboardControllerProvider);
    final parents = ref.watch(
      familyControllerProvider.select(
        (s) => [
          for (final m in s.value ?? const <FamilyMember>[])
            if (m.role == Role.parent) m,
        ],
      ),
    );

    final sending = _request.phase == SubmitPhase.sending;
    return PopScope(
      canPop: !sending,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Palette.background,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.actionClose,
            onPressed: sending ? null : () => context.pop(),
          ),
          title: Text(
            l10n.payoutCashOut,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        body: SafeArea(
          child: dashboard.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                ErrorCard(
                  message: apiErrorMessage(l10n, e),
                  onRetry: () => ref.invalidate(dashboardControllerProvider),
                ),
              ],
            ),
            data: (data) => data == null
                ? const Center(child: CircularProgressIndicator())
                : _body(context, data, parents),
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    Dashboard data,
    List<FamilyMember> parents,
  ) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).languageCode;
    final locked = _request.isLocked;
    final ambiguous = _request.phase == SubmitPhase.ambiguous;

    // Something changed since the teen opened the form (a penalty, an open
    // request from another phone). While an attempt is in flight or unsure the
    // form stays, so the retry stays visible.
    final rule = cashOutState(
      data.balance,
      hasOpenRequest: data.openPayout != null,
    );
    if (rule is! CashOutAllowed && !_done && !locked) {
      return _blocked(context, rule, locale);
    }

    final available = data.balance.available;
    final typed = _amount.text.trim().isNotEmpty;
    final check = validatePayoutAmount(_amount.text, available: available);
    final parentId = _parentId(parents);
    final canSend = check.isValid && parentId != null;

    String? amountError = _amountServerError;
    if (amountError == null && typed && !check.isValid) {
      amountError = switch (check.error!) {
        PayoutAmountError.invalid => l10n.errAmountInvalid,
        PayoutAmountError.notPositive => l10n.errPayoutAmountPositive,
        PayoutAmountError.belowMinimum => l10n.errPayoutBelowMin(
          formatMoney(kMinPayout, locale: locale),
        ),
        PayoutAmountError.aboveAvailable => l10n.errPayoutAboveAvailable(
          formatMoney(available, locale: locale),
        ),
      };
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        Text(
          l10n.payoutAvailable(formatMoney(available, locale: locale)),
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: Space.s16),
        if (ambiguous) ...[
          InfoBanner(l10n.payoutUnsure),
          const SizedBox(height: Space.s16),
        ],
        TextField(
          controller: _amount,
          enabled: !locked,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\s,.]')),
          ],
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l10n.fieldPayoutAmount,
            helperText: l10n.payoutMinHint(
              formatMoney(kMinPayout, locale: locale),
            ),
            helperMaxLines: 2,
            errorText: amountError,
            errorMaxLines: 3,
          ),
          onChanged: (_) {
            _edited();
          },
        ),
        const SizedBox(height: Space.s24),
        if (parents.length == 1)
          Text(l10n.payoutTo(parents.single.displayName), style: text.bodyLarge)
        else if (parents.length > 1) ...[
          Semantics(
            header: true,
            child: Text(
              l10n.payoutAsk,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          RadioGroup<String>(
            groupValue: parentId,
            onChanged: (id) {
              if (locked || id == null) return;
              _edited();
              setState(() => _chosenParentId = id);
            },
            child: Column(
              children: [
                for (final p in parents)
                  RadioListTile<String>(
                    value: p.id,
                    enabled: !locked,
                    contentPadding: EdgeInsets.zero,
                    title: Text(p.displayName),
                  ),
              ],
            ),
          ),
        ],
        if (_formError != null) ...[
          const SizedBox(height: Space.s16),
          Text(
            _formError!,
            style: text.bodyMedium?.copyWith(color: Palette.warn, height: 1.5),
          ),
        ],
        const SizedBox(height: Space.s24),
        if (_alreadyOpen)
          FilledButton(
            onPressed: () => context.pop(),
            child: Text(l10n.payoutBackHome),
          )
        else
          BusyButton(
            busy: _request.phase == SubmitPhase.sending,
            onPressed: ambiguous || canSend
                ? () => _submit(parents, data)
                : null,
            child: Text(ambiguous ? l10n.actionTryAgain : l10n.payoutSend),
          ),
        if (ambiguous)
          TextButton(
            onPressed: _confirmEdit,
            child: Text(l10n.createEditDetails),
          ),
      ],
    );
  }

  Widget _blocked(BuildContext context, CashOutState rule, String locale) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Text(
          cashOutExplanation(l10n, rule, locale) ?? '',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: Palette.muted, height: 1.5),
        ),
        const SizedBox(height: Space.s24),
        FilledButton(
          onPressed: () => context.pop(),
          child: Text(l10n.payoutBackHome),
        ),
      ],
    );
  }
}
