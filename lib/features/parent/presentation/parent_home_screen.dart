import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiyn_app/app/router/routes.dart';
import 'package:tiyn_app/core/lifecycle/refresh_on_foreground.dart';
import 'package:tiyn_app/core/network/error_messages.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/app_card.dart';
import 'package:tiyn_app/design/widgets/error_card.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/presentation/join_code_panel.dart';
import 'package:tiyn_app/features/parent/application/parent_tabs.dart';
import 'package:tiyn_app/features/parent/application/teen_status.dart';
import 'package:tiyn_app/features/parent/presentation/add_teen_sheet.dart';
import 'package:tiyn_app/features/tasks/data/task.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// "My teens": one row per linked teen with what needs the parent's attention.
/// With nobody linked yet the join code is the page.
class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) => Future.wait([
    ref.read(familyControllerProvider.notifier).refresh(),
    ref.read(submittedTasksProvider.notifier).refresh(),
    ref.read(assignedTasksProvider.notifier).refresh(),
  ]);

  /// Null while loading or failed: a status computed from the empty list that
  /// stands in before sign-in would wrongly say "Nothing active".
  List<Task>? _loaded(AsyncValue<List<Task>> tasks) =>
      tasks.isLoading || tasks.hasError ? null : tasks.value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final family = ref.watch(familyControllerProvider);
    final joinCode = ref.watch(
      authControllerProvider.select((s) => s.value?.joinCode ?? ''),
    );
    final submitted = ref.watch(submittedTasksProvider);
    final assigned = ref.watch(assignedTasksProvider);

    final tasksFailed = submitted.hasError || assigned.hasError;
    final tasksError = submitted.error ?? assigned.error;

    // `when`, not `.value`: while the family reloads (or after a failed first
    // load) the previous value is still the empty list from before sign-in,
    // which must not read as "no teens".
    final body = family.when(
      loading: () => const [
        Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (e, _) => [
        ErrorCard(
          message: apiErrorMessage(l10n, e),
          onRetry: () => ref.invalidate(familyControllerProvider),
        ),
      ],
      data: (members) {
        final teens = members.where((m) => m.role == Role.teen).toList();
        if (teens.isEmpty) return [_NoTeens(joinCode: joinCode)];
        return [
          _Header(onAdd: () => showAddTeenSheet(context, joinCode: joinCode)),
          const SizedBox(height: Space.s16),
          if (tasksFailed) ...[
            ErrorCard(
              message: apiErrorMessage(l10n, tasksError!),
              onRetry: () {
                ref.invalidate(submittedTasksProvider);
                ref.invalidate(assignedTasksProvider);
              },
            ),
            const SizedBox(height: Space.s12),
          ],
          for (final row in teenOverview(
            teens,
            submitted: _loaded(submitted),
            assigned: _loaded(assigned),
          ))
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s8),
              child: _TeenRow(
                row: row,
                loading: !tasksFailed,
                onTap: () => context.push(Routes.parentTeen(row.teen.id)),
                onNewTask: () => context.push(Routes.parentNewFor(row.teen.id)),
              ),
            ),
        ];
      },
    );

    return RefreshOnForeground(
      tab: ParentTab.home,
      onRefresh: () => _refresh(ref),
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              children: [
                ...body,
                const SizedBox(height: Space.s24),
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
}

class _Header extends StatelessWidget {
  const _Header({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              l10n.parentHomeTitle,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: Text(l10n.parentHomeAdd),
        ),
      ],
    );
  }
}

class _NoTeens extends StatelessWidget {
  const _NoTeens({required this.joinCode});

  final String joinCode;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Space.s16),
        Semantics(
          header: true,
          child: Text(
            l10n.parentCodeTitle,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: Space.s8),
        Text(
          l10n.parentCodeSubtitle,
          style: text.bodyMedium?.copyWith(color: Palette.muted, height: 1.5),
        ),
        const SizedBox(height: Space.s32),
        JoinCodePanel(joinCode: joinCode),
      ],
    );
  }
}

class _TeenRow extends StatelessWidget {
  const _TeenRow({
    required this.row,
    required this.loading,
    required this.onTap,
    required this.onNewTask,
  });

  final TeenOverview row;
  final VoidCallback onTap;
  final VoidCallback onNewTask;

  /// True while the status is not known yet (as opposed to failed).
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final name = row.teen.displayName;
    final l10n = AppLocalizations.of(context);
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MergeSemantics(
            child: Row(
              children: [
                ExcludeSemantics(
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Palette.gold,
                    child: Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Space.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Space.s4),
                      _StatusLine(status: row.status, loading: loading),
                    ],
                  ),
                ),
                const SizedBox(width: Space.s8),
                const ExcludeSemantics(
                  child: Icon(Icons.chevron_right, color: Palette.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.s4),
          TextButton.icon(
            onPressed: onNewTask,
            icon: const Icon(Icons.add),
            label: Text(l10n.createNewTaskTooltip),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.status, required this.loading});

  final TeenStatus? status;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final status = this.status;
    if (status == null) {
      // Failed lists are explained once, above the rows.
      return loading
          ? Container(
              width: 72,
              height: 12,
              decoration: BoxDecoration(
                color: Palette.line,
                borderRadius: BorderRadius.circular(6),
              ),
            )
          : const SizedBox.shrink();
    }
    return switch (status.kind) {
      TeenStatusKind.toCheck => DecoratedBox(
        decoration: BoxDecoration(
          color: Palette.goldWash,
          borderRadius: BorderRadius.circular(Radii.input),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            l10n.teenStatusToCheck(status.count),
            style: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      TeenStatusKind.active => Text(
        l10n.teenStatusActive(status.count),
        style: text.bodyMedium?.copyWith(color: Palette.muted),
      ),
      TeenStatusKind.idle => Text(
        l10n.teenStatusIdle,
        style: text.bodyMedium?.copyWith(color: Palette.muted),
      ),
    };
  }
}
