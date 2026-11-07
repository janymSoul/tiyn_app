import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiyn_app/app/router/routes.dart';
import 'package:tiyn_app/core/format/deadline_label.dart';
import 'package:tiyn_app/core/lifecycle/refresh_on_foreground.dart';
import 'package:tiyn_app/core/network/error_messages.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/error_card.dart';
import 'package:tiyn_app/design/widgets/money_text.dart';
import 'package:tiyn_app/design/widgets/state_chip.dart';
import 'package:tiyn_app/design/widgets/task_card.dart';
import 'package:tiyn_app/features/teen/application/dashboard_controller.dart';
import 'package:tiyn_app/features/teen/application/milestone_rule.dart';
import 'package:tiyn_app/features/teen/application/teen_home_model.dart';
import 'package:tiyn_app/features/teen/presentation/proof_sheet.dart';
import 'package:tiyn_app/features/teen/presentation/teen_home_screen.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// A milestone with its steps. Each step opens its task; the milestone itself
/// can be submitted only once every step is approved.
class TeenMilestoneScreen extends ConsumerWidget {
  const TeenMilestoneScreen({super.key, required this.milestoneId});

  final String milestoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final dashboard = ref.watch(dashboardControllerProvider);
    Future<void> refresh() =>
        ref.read(dashboardControllerProvider.notifier).refresh();

    Widget body(Widget child) => ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [child],
    );

    final content = dashboard.when(
      skipLoadingOnReload: true,
      loading: () => body(
        const Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => body(
        ErrorCard(
          message: apiErrorMessage(l10n, e),
          onRetry: () => ref.invalidate(dashboardControllerProvider),
        ),
      ),
      data: (data) {
        final group = data == null
            ? null
            : groupDashboard(data).milestones
                  .where((g) => g.milestone.id == milestoneId)
                  .firstOrNull;
        if (group == null) {
          // Gone from the recent window, or cancelled: nothing to show.
          return body(
            ErrorCard(message: l10n.errorTaskChanged, onRetry: refresh),
          );
        }
        final rule = milestoneSubmitRule(group.milestone.state, group.progress);
        final m = group.milestone;
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      m.title,
                      style: text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Space.s12),
                MoneyText(
                  m.reward,
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: Space.s8),
            Wrap(
              spacing: Space.s12,
              runSpacing: Space.s8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  deadlineLabel(
                    l10n,
                    MaterialLocalizations.of(context),
                    m.deadlineAt,
                    now: DateTime.now(),
                  ),
                  style: text.bodyMedium?.copyWith(color: Palette.muted),
                ),
                StateChip(m.state),
              ],
            ),
            if (m.description.isNotEmpty) ...[
              const SizedBox(height: Space.s12),
              Text(m.description, style: text.bodyLarge?.copyWith(height: 1.5)),
            ],
            const SizedBox(height: Space.s16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: group.progress.fraction,
                minHeight: 8,
                backgroundColor: Palette.line,
                color: Palette.gold,
              ),
            ),
            const SizedBox(height: Space.s4),
            Text(
              l10n.milestoneStepsApproved(
                group.progress.done,
                group.progress.total,
              ),
              style: text.bodySmall?.copyWith(color: Palette.muted),
            ),
            const SizedBox(height: Space.s24),
            Semantics(
              header: true,
              child: Text(
                l10n.milestoneStepsTitle,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: Space.s8),
            if (group.steps.isEmpty)
              Text(
                l10n.milestoneNoTasks,
                style: text.bodyMedium?.copyWith(color: Palette.muted),
              ),
            for (final step in group.steps)
              TaskCard(
                title: step.title,
                reward: step.reward,
                deadlineAt: step.deadlineAt,
                state: step.state,
                onTap: () => context.push(Routes.teenTask(step.id)),
              ),
            if (rule.kind != MilestoneSubmitKind.notApplicable) ...[
              const SizedBox(height: Space.s16),
              FilledButton(
                onPressed: rule.canSubmit
                    ? () => showProofSheet(context, taskId: m.id)
                    : null,
                child: Text(l10n.teenSubmitMilestone),
              ),
              if (!rule.canSubmit) ...[
                const SizedBox(height: Space.s8),
                // Say why it is disabled, not just grey it out.
                Text(
                  rule.kind == MilestoneSubmitKind.noSteps
                      ? l10n.milestoneBlockedEmpty
                      : l10n.milestoneBlockedPending(
                          rule.progress.done,
                          rule.progress.total,
                        ),
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: Palette.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );

    return RefreshOnForeground(
      tab: TeenTab.home,
      onRefresh: () => unawaited(refresh()),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Palette.background,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: SafeArea(
          child: RefreshIndicator(onRefresh: refresh, child: content),
        ),
      ),
    );
  }
}
