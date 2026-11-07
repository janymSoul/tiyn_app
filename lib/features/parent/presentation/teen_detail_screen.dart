import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiyn_app/app/router/routes.dart';
import 'package:tiyn_app/core/lifecycle/refresh_on_foreground.dart';
import 'package:tiyn_app/core/network/error_messages.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/error_card.dart';
import 'package:tiyn_app/design/widgets/task_card.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/parent/application/parent_tabs.dart';
import 'package:tiyn_app/features/parent/application/teen_tasks.dart';
import 'package:tiyn_app/features/tasks/application/milestone_progress.dart';
import 'package:tiyn_app/features/tasks/application/task_providers.dart';
import 'package:tiyn_app/features/tasks/data/task.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

enum _Section { tasks, milestones }

/// One teen's tasks and milestones. This is the only screen that loads the
/// full history (`GET /tasks?teenId=`).
class TeenDetailScreen extends ConsumerStatefulWidget {
  const TeenDetailScreen({super.key, required this.teenId});

  final String teenId;

  @override
  ConsumerState<TeenDetailScreen> createState() => _TeenDetailScreenState();
}

class _TeenDetailScreenState extends ConsumerState<TeenDetailScreen> {
  _Section _section = _Section.tasks;

  TaskQuery get _query => TaskQuery.forTeen(widget.teenId);

  // The teen's own list, plus the two lists the home screen and the badge
  // read, so they are fresh when the parent goes back.
  Future<void> _refresh() => Future.wait([
    ref.read(taskListProvider(_query).notifier).refresh(),
    ref.read(submittedTasksProvider.notifier).refresh(),
    ref.read(assignedTasksProvider.notifier).refresh(),
  ]);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tasks = ref.watch(taskListProvider(_query));
    final name = ref.watch(
      familyControllerProvider.select(
        (s) =>
            s.value
                ?.where((m) => m.id == widget.teenId)
                .map((m) => m.displayName)
                .firstOrNull ??
            '',
      ),
    );

    return RefreshOnForeground(
      tab: ParentTab.home,
      onRefresh: _refresh,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Palette.background,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          leading: BackButton(
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: _section == _Section.milestones
                  ? l10n.createNewMilestoneTooltip
                  : l10n.createNewTaskTooltip,
              onPressed: () => context.push(
                Routes.parentNewFor(
                  widget.teenId,
                  milestone: _section == _Section.milestones,
                ),
              ),
            ),
          ],
          title: Text(
            name,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        body: SafeArea(
          child: tasks.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                ErrorCard(
                  message: apiErrorMessage(l10n, e),
                  onRetry: () => ref.invalidate(taskListProvider(_query)),
                ),
              ],
            ),
            data: (all) {
              final groups = groupTeenTasks(all);
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, Space.s12),
                    child: SegmentedButton<_Section>(
                      showSelectedIcon: false,
                      expandedInsets: EdgeInsets.zero,
                      segments: [
                        ButtonSegment(
                          value: _Section.tasks,
                          label: Text(
                            l10n.teenTabTasks(groups.openTasks.length),
                          ),
                        ),
                        ButtonSegment(
                          value: _Section.milestones,
                          label: Text(
                            l10n.teenTabMilestones(
                              groups.openMilestones.length,
                            ),
                          ),
                        ),
                      ],
                      selected: {_section},
                      onSelectionChanged: (s) =>
                          setState(() => _section = s.single),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                        children: switch (_section) {
                          _Section.tasks => _taskRows(l10n, groups),
                          _Section.milestones => _milestoneRows(l10n, groups),
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _taskRows(AppLocalizations l10n, TeenTasks groups) {
    final open = groups.openTasks;
    final finished = groups.finishedTasks;
    return [
      if (open.isEmpty)
        _EmptyText(finished.isEmpty ? l10n.teenNoTasks : l10n.teenNothingOpen),
      for (final t in open) _TaskRow(task: t),
      if (finished.isNotEmpty)
        _FinishedGroup(
          label: l10n.teenFinished(finished.length),
          children: [for (final t in finished) _TaskRow(task: t)],
        ),
    ];
  }

  List<Widget> _milestoneRows(AppLocalizations l10n, TeenTasks groups) {
    final open = groups.openMilestones;
    final finished = groups.finishedMilestones;
    Widget row(Task m) =>
        _MilestoneRow(milestone: m, progress: groups.progress[m.id]!);
    return [
      if (open.isEmpty)
        _EmptyText(
          finished.isEmpty ? l10n.teenNoMilestones : l10n.teenNothingOpen,
        ),
      for (final m in open) row(m),
      if (finished.isNotEmpty)
        _FinishedGroup(
          label: l10n.teenFinished(finished.length),
          children: [for (final m in finished) row(m)],
        ),
    ];
  }
}

Widget _card(Task task, List<Widget> children) => TaskCard(
  title: task.title,
  reward: task.reward,
  deadlineAt: task.deadlineAt,
  state: task.state,
  children: children,
);

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return _card(task, const []);
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.milestone, required this.progress});

  final Task milestone;
  final MilestoneProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return _card(milestone, [
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
    ]);
  }
}

class _FinishedGroup extends StatelessWidget {
  const _FinishedGroup({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: Palette.muted),
        ),
        children: children,
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.s24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: Palette.muted),
      ),
    );
  }
}
