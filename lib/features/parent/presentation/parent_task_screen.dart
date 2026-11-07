import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiyn_app/app/router/routes.dart';
import 'package:tiyn_app/core/format/deadline_label.dart';
import 'package:tiyn_app/core/lifecycle/refresh_on_foreground.dart';
import 'package:tiyn_app/core/money/money_format.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/error_messages.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/app_card.dart';
import 'package:tiyn_app/design/widgets/busy_button.dart';
import 'package:tiyn_app/design/widgets/error_card.dart';
import 'package:tiyn_app/design/widgets/money_text.dart';
import 'package:tiyn_app/design/widgets/state_chip.dart';
import 'package:tiyn_app/design/widgets/task_card.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/parent/application/parent_tabs.dart';
import 'package:tiyn_app/features/parent/application/teen_tasks.dart';
import 'package:tiyn_app/features/tasks/application/milestone_progress.dart';
import 'package:tiyn_app/features/tasks/application/task_detail_provider.dart';
import 'package:tiyn_app/features/tasks/application/task_providers.dart';
import 'package:tiyn_app/features/tasks/data/task.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// A task or a milestone as the parent sees it. A milestone also lists its
/// steps and offers "Add task to this milestone". Cancel is offered only
/// while the task is `ASSIGNED` or `SUBMITTED`, and always asks first.
class ParentTaskScreen extends ConsumerStatefulWidget {
  const ParentTaskScreen({
    super.key,
    required this.teenId,
    required this.taskId,
  });

  final String teenId;
  final String taskId;

  @override
  ConsumerState<ParentTaskScreen> createState() => _ParentTaskScreenState();
}

class _ParentTaskScreenState extends ConsumerState<ParentTaskScreen> {
  bool _busy = false;

  TaskQuery get _query => TaskQuery.forTeen(widget.teenId);

  /// Everything that shows this task: its own detail, the teen's list (which
  /// the steps come from) and the two lists behind the home screen and badge.
  Future<void> _refresh() {
    ref.invalidate(taskDetailProvider(widget.taskId));
    return Future.wait([
      ref.read(taskListProvider(_query).notifier).refresh(),
      ref.read(submittedTasksProvider.notifier).refresh(),
      ref.read(assignedTasksProvider.notifier).refresh(),
    ]);
  }

  Future<void> _cancel(Task task) async {
    if (_busy) return;
    final confirmed = await _confirmCancel(task);
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(taskRepositoryProvider).cancel(task.id);
      unawaited(_refresh());
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (e.code == 'invalid_transition' ||
          e.code == 'concurrent_modification') {
        // It moved on before the parent confirmed: show how it is now.
        messenger.showSnackBar(SnackBar(content: Text(l10n.reviewChanged)));
        unawaited(_refresh());
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(apiErrorMessage(l10n, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmCancel(Task task) {
    final l10n = AppLocalizations.of(context);
    final milestone = task.kind == TaskKind.milestone;
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
                  milestone
                      ? l10n.parentCancelMilestoneTitle
                      : l10n.parentCancelTaskTitle,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: Space.s8),
              Text(
                task.title,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: Space.s8),
              Text(
                l10n.parentCancelBody,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Palette.muted, height: 1.5),
              ),
              const SizedBox(height: Space.s20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.parentKeepIt),
              ),
              const SizedBox(height: Space.s4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Palette.warn),
                child: Text(l10n.parentConfirmCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addStep(Task milestone) async {
    await context.push(
      Routes.parentNewFor(
        milestone.teenId,
        milestoneId: milestone.id,
        milestoneDeadline: milestone.deadlineAt,
      ),
    );
    // A step may have been added: the progress counters come from the server.
    if (mounted) unawaited(_refresh());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final task = ref.watch(taskDetailProvider(widget.taskId));
    final names = ref.watch(familyNamesProvider);

    return RefreshOnForeground(
      tab: ParentTab.home,
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
            child: task.when(
              skipLoadingOnReload: true,
              loading: () => ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
              error: (e, _) => ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  ErrorCard(
                    message: apiErrorMessage(l10n, e),
                    onRetry: () =>
                        ref.invalidate(taskDetailProvider(widget.taskId)),
                  ),
                ],
              ),
              data: (t) => _content(context, t, names[t.teenId] ?? ''),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Task task, String teenName) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).languageCode;
    final milestone = task.kind == TaskKind.milestone;
    final note = task.decisionNote;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        if (teenName.isNotEmpty)
          Text(
            teenName,
            style: text.bodyMedium?.copyWith(color: Palette.muted),
          ),
        const SizedBox(height: Space.s4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  task.title,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: Space.s12),
            MoneyText(
              task.reward,
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
                task.deadlineAt,
                now: DateTime.now(),
              ),
              style: text.bodyMedium?.copyWith(color: Palette.muted),
            ),
            StateChip(task.state),
          ],
        ),
        if (task.description.isNotEmpty) ...[
          const SizedBox(height: Space.s12),
          Text(task.description, style: text.bodyLarge?.copyWith(height: 1.5)),
        ],
        if (!task.penalty.isZero) ...[
          const SizedBox(height: Space.s12),
          Text(
            l10n.teenPenaltyLine(formatMoney(task.penalty, locale: locale)),
            style: text.bodyMedium?.copyWith(color: Palette.warn),
          ),
        ],
        if (note != null && note.isNotEmpty) ...[
          const SizedBox(height: Space.s16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.parentNoteLabel,
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Palette.infoText,
                  ),
                ),
                const SizedBox(height: Space.s4),
                Text(note, style: text.bodyLarge?.copyWith(height: 1.5)),
              ],
            ),
          ),
        ],
        if (milestone) ..._steps(context, task),
        if (task.state.canCancel) ...[
          const SizedBox(height: Space.s24),
          BusyButton(
            outlined: true,
            busy: _busy,
            onPressed: () => _cancel(task),
            child: Text(
              milestone ? l10n.parentCancelMilestone : l10n.parentCancelTask,
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _steps(BuildContext context, Task milestone) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final all = ref.watch(taskListProvider(_query));

    return [
      const SizedBox(height: Space.s24),
      Semantics(
        header: true,
        child: Text(
          l10n.milestoneStepsTitle,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(height: Space.s8),
      // `when`, not `.value`: a failed load must not read as "no steps".
      ...all.when(
        loading: () => const [
          Padding(
            padding: EdgeInsets.all(Space.s24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
        error: (e, _) => [
          ErrorCard(
            message: apiErrorMessage(l10n, e),
            onRetry: () => ref.invalidate(taskListProvider(_query)),
          ),
        ],
        data: (list) {
          final steps = [
            for (final t in list)
              if (t.milestoneId == milestone.id) t,
          ]..sort((a, b) => a.deadlineAt.compareTo(b.deadlineAt));
          // The server's counters when it sent them, else count the steps.
          final progress = milestone.totalTasks != null
              ? MilestoneProgress(
                  done: milestone.approvedTasks ?? 0,
                  total: milestone.totalTasks!,
                )
              : milestoneProgress(milestone.id, list);
          return [
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
            const SizedBox(height: Space.s12),
            for (final step in steps)
              TaskCard(
                title: step.title,
                reward: step.reward,
                deadlineAt: step.deadlineAt,
                state: step.state,
                onTap: () =>
                    context.push(Routes.parentTask(step.teenId, step.id)),
              ),
            if (milestone.state == TaskState.assigned) ...[
              const SizedBox(height: Space.s8),
              OutlinedButton.icon(
                onPressed: () => _addStep(milestone),
                icon: const Icon(Icons.add),
                label: Text(l10n.parentAddToMilestone),
              ),
            ],
          ];
        },
      ),
    ];
  }
}
