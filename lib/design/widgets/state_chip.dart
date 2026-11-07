import 'package:flutter/material.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// One colour and one word per [TaskState]. The word is always shown, so the
/// state never depends on colour alone.
class StateChip extends StatelessWidget {
  const StateChip(this.state, {super.key});

  final TaskState state;

  static ({Color background, Color foreground}) colors(TaskState state) =>
      switch (state) {
        TaskState.assigned => (
          background: Palette.infoWash,
          foreground: Palette.infoText,
        ),
        TaskState.submitted => (
          background: Palette.goldWash,
          foreground: Palette.navy,
        ),
        TaskState.approved => (
          background: Palette.successWash,
          foreground: Palette.successText,
        ),
        TaskState.rejected => (
          background: Palette.warnWash,
          foreground: Palette.warn,
        ),
        TaskState.cancelled => (
          background: Palette.line,
          foreground: Palette.muted,
        ),
        TaskState.expired => (
          background: Palette.line,
          foreground: Palette.warn,
        ),
      };

  static String label(AppLocalizations l10n, TaskState state) =>
      switch (state) {
        TaskState.assigned => l10n.taskStateAssigned,
        TaskState.submitted => l10n.taskStateSubmitted,
        TaskState.approved => l10n.taskStateApproved,
        TaskState.rejected => l10n.taskStateRejected,
        TaskState.cancelled => l10n.taskStateCancelled,
        TaskState.expired => l10n.taskStateExpired,
      };

  @override
  Widget build(BuildContext context) {
    final c = colors(state);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(Radii.input),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label(AppLocalizations.of(context), state),
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: c.foreground, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
