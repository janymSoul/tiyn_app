import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiyn_app/core/format/deadline_label.dart';
import 'package:tiyn_app/core/lifecycle/refresh_on_foreground.dart';
import 'package:tiyn_app/core/money/money_format.dart';
import 'package:tiyn_app/core/network/error_messages.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/app_card.dart';
import 'package:tiyn_app/design/widgets/error_card.dart';
import 'package:tiyn_app/design/widgets/money_text.dart';
import 'package:tiyn_app/design/widgets/state_chip.dart';
import 'package:tiyn_app/features/tasks/application/task_detail_provider.dart';
import 'package:tiyn_app/features/tasks/data/task.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';
import 'package:tiyn_app/features/teen/application/dashboard_controller.dart';
import 'package:tiyn_app/features/teen/presentation/proof_sheet.dart';
import 'package:tiyn_app/features/teen/presentation/teen_home_screen.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// One task as the teen sees it: what it is, what to do next, and how it went.
class TeenTaskScreen extends ConsumerWidget {
  const TeenTaskScreen({super.key, required this.taskId});

  final String taskId;

  Future<void> _refresh(WidgetRef ref) {
    ref.invalidate(taskDetailProvider(taskId));
    return ref.read(dashboardControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final task = ref.watch(taskDetailProvider(taskId));
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
                    onRetry: () => ref.invalidate(taskDetailProvider(taskId)),
                  ),
                ],
              ),
              data: (t) => _TaskBody(task: t),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskBody extends ConsumerWidget {
  const _TaskBody({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).languageCode;
    final note = task.decisionNote;
    final redo = task.state == TaskState.assigned && note != null;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        if (redo) ...[
          _NoteBanner(title: l10n.teenRedoTitle, note: note),
          const SizedBox(height: Space.s16),
        ],
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
          const SizedBox(height: Space.s16),
          Text(task.description, style: text.bodyLarge?.copyWith(height: 1.5)),
        ],
        if (!task.penalty.isZero && task.state == TaskState.assigned) ...[
          const SizedBox(height: Space.s12),
          Text(
            l10n.teenPenaltyLine(formatMoney(task.penalty, locale: locale)),
            style: text.bodyMedium?.copyWith(color: Palette.warn),
          ),
        ],
        const SizedBox(height: Space.s24),
        _Outcome(task: task),
      ],
    );
  }
}

/// What the teen can do, or how it ended, for each state.
class _Outcome extends ConsumerWidget {
  const _Outcome({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).languageCode;

    Widget line(String message, {Color? color}) => Text(
      message,
      style: text.bodyLarge?.copyWith(
        color: color ?? Palette.muted,
        height: 1.5,
      ),
    );

    return switch (task.state) {
      TaskState.assigned => FilledButton(
        onPressed: () => showProofSheet(context, taskId: task.id),
        child: Text(l10n.teenSubmitProof),
      ),
      TaskState.submitted => line(l10n.teenWaiting),
      TaskState.approved => Text(
        formatMoney(task.reward, locale: locale, signed: true),
        style: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Palette.successText,
        ),
      ),
      TaskState.rejected => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          line(l10n.teenRejectedLine, color: Palette.warn),
          if (task.decisionNote case final note?) ...[
            const SizedBox(height: Space.s12),
            _NoteBanner(title: l10n.teenNoteFromParent, note: note),
          ],
        ],
      ),
      TaskState.expired => line(l10n.teenExpiredLine, color: Palette.warn),
      TaskState.cancelled => line(l10n.teenCancelledLine),
    };
  }
}

class _NoteBanner extends StatelessWidget {
  const _NoteBanner({required this.title, required this.note});

  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Palette.infoText,
            ),
          ),
          const SizedBox(height: Space.s4),
          Text(note, style: text.bodyLarge?.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}
