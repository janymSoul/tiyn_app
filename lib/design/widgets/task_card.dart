import 'package:flutter/material.dart';
import 'package:tiyn_app/core/format/deadline_label.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/app_card.dart';
import 'package:tiyn_app/design/widgets/money_text.dart';
import 'package:tiyn_app/design/widgets/state_chip.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// A task or milestone as a card: title and reward, then deadline and state
/// chip, then any [children] (progress, steps). Used by both roles, so it
/// takes plain values instead of one of the two task models.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.title,
    required this.reward,
    required this.deadlineAt,
    required this.state,
    this.children = const [],
    this.onTap,
  });

  final String title;
  final Money reward;
  final DateTime deadlineAt;
  final TaskState state;
  final List<Widget> children;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s8),
      child: MergeSemantics(
        child: AppCard(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.s12),
                  MoneyText(
                    reward,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
                      deadlineAt,
                      now: DateTime.now(),
                    ),
                    style: text.bodyMedium?.copyWith(color: Palette.muted),
                  ),
                  StateChip(state),
                ],
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
