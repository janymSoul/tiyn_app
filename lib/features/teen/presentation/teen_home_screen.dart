import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiyn_app/app/router/routes.dart';
import 'package:tiyn_app/core/lifecycle/refresh_on_foreground.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/money/money_format.dart';
import 'package:tiyn_app/core/network/error_messages.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/coin_badge.dart';
import 'package:tiyn_app/design/widgets/error_card.dart';
import 'package:tiyn_app/design/widgets/state_chip.dart';
import 'package:tiyn_app/design/widgets/task_card.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';
import 'package:tiyn_app/features/teen/application/dashboard_controller.dart';
import 'package:tiyn_app/features/teen/application/teen_home_model.dart';
import 'package:tiyn_app/features/teen/data/dashboard.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// The teen has no tabs in Phase 1, so the only "tab" is Home.
enum TeenTab { home }

/// Balance, what is waiting for a check, and the work to do. One call:
/// `GET /dashboard`.
class TeenHomeScreen extends ConsumerWidget {
  const TeenHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final dashboard = ref.watch(dashboardControllerProvider);
    final name = ref.watch(
      authControllerProvider.select((s) => s.value?.displayName ?? ''),
    );
    final parents = ref.watch(
      familyControllerProvider.select(
        (s) => [
          for (final p in s.value ?? const <FamilyMember>[]) p.displayName,
        ],
      ),
    );

    Future<void> refresh() =>
        ref.read(dashboardControllerProvider.notifier).refresh();

    // `when`, not `.value`: see ParentHomeScreen. A reload shows the spinner
    // and a failed first load shows the error.
    final body = dashboard.when(
      loading: () => const <Widget>[
        Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (e, _) => [
        ErrorCard(
          message: apiErrorMessage(l10n, e),
          onRetry: () => ref.invalidate(dashboardControllerProvider),
        ),
      ],
      data: (data) => data == null ? const <Widget>[] : _content(context, data),
    );

    return RefreshOnForeground(
      tab: TeenTab.home,
      onRefresh: refresh,
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.teenGreeting(name),
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: Space.s16),
                ...body,
                const SizedBox(height: Space.s32),
                if (parents.isNotEmpty)
                  Text(
                    l10n.teenConnectedTo(parents.join(', ')),
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(color: Palette.muted),
                  ),
                TextButton(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
                  child: Text(l10n.actionSignOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, Dashboard data) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).languageCode;
    final home = groupDashboard(data);

    return [
      Center(
        child: CoinBadge(
          size: 180,
          glyph: formatMoney(data.balance.available, locale: locale),
        ),
      ),
      if (!data.pending.isZero) ...[
        const SizedBox(height: Space.s16),
        Center(child: _PendingChip(amount: data.pending)),
      ],
      const SizedBox(height: Space.s24),
      if (home.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.s16),
          child: Text(
            l10n.teenNothingToDo,
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: Palette.muted),
          ),
        ),
      if (home.chores.isNotEmpty) ...[
        _SectionTitle(l10n.teenTasksTitle),
        for (final chore in home.chores) _choreCard(context, chore),
      ],
      if (home.milestones.isNotEmpty) ...[
        _SectionTitle(l10n.teenMilestonesTitle),
        for (final group in home.milestones) _MilestoneCard(group: group),
      ],
    ];
  }

  Widget _choreCard(BuildContext context, DashboardTask chore) => TaskCard(
    title: chore.title,
    reward: chore.reward,
    deadlineAt: chore.deadlineAt,
    state: chore.state,
    onTap: () => context.push(Routes.teenTask(chore.id)),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.s8, bottom: Space.s8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// "1 500 ₸ waiting for check": a label, not a button.
class _PendingChip extends StatelessWidget {
  const _PendingChip({required this.amount});

  final Money amount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Palette.goldWash,
        borderRadius: BorderRadius.circular(Radii.input),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExcludeSemantics(
              child: Icon(Icons.hourglass_empty, size: 16),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l10n.teenPendingChip(formatMoney(amount, locale: locale)),
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.group});

  final MilestoneGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final m = group.milestone;
    final progress = group.progress;
    return TaskCard(
      title: m.title,
      reward: m.reward,
      deadlineAt: m.deadlineAt,
      state: m.state,
      onTap: () => context.push(Routes.teenMilestone(m.id)),
      children: [
        const SizedBox(height: Space.s8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.fraction,
            minHeight: 8,
            backgroundColor: Palette.line,
            color: Palette.gold,
          ),
        ),
        const SizedBox(height: Space.s4),
        Text(
          progress.total == 0
              ? l10n.milestoneNoTasks
              : l10n.milestoneProgress(progress.done, progress.total),
          style: text.bodySmall?.copyWith(color: Palette.muted),
        ),
        for (final step in group.steps) ...[
          const SizedBox(height: Space.s12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(step.title, style: text.bodyMedium)),
              const SizedBox(width: Space.s8),
              StateChip(step.state),
            ],
          ),
        ],
      ],
    );
  }
}
