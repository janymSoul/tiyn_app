import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiyn_app/app/router/routes.dart';
import 'package:tiyn_app/core/lifecycle/refresh_on_foreground.dart';
import 'package:tiyn_app/core/network/error_messages.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/app_card.dart';
import 'package:tiyn_app/design/widgets/error_card.dart';
import 'package:tiyn_app/design/widgets/money_text.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/parent/application/parent_tabs.dart';
import 'package:tiyn_app/features/parent/application/review_providers.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// "To check": every `SUBMITTED` task of every teen, oldest first.
class ReviewListScreen extends ConsumerWidget {
  const ReviewListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final submitted = ref.watch(submittedTasksProvider);
    final names = ref.watch(familyNamesProvider);
    Future<void> refresh() =>
        ref.read(submittedTasksProvider.notifier).refresh();

    final body = submitted.when(
      loading: () => const <Widget>[
        Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (e, _) => [
        ErrorCard(
          message: apiErrorMessage(l10n, e),
          onRetry: () => ref.invalidate(submittedTasksProvider),
        ),
      ],
      data: (tasks) {
        if (tasks.isEmpty) {
          return [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.s32),
              child: Text(
                l10n.reviewEmpty,
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: Palette.muted),
              ),
            ),
          ];
        }
        return [
          for (final task in reviewQueue(tasks))
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s8),
              child: AppCard(
                onTap: () => context.push(Routes.parentReviewTask(task.id)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            names[task.teenId] ?? '',
                            style: text.bodySmall?.copyWith(
                              color: Palette.muted,
                            ),
                          ),
                          const SizedBox(height: Space.s4),
                          Text(
                            task.title,
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Space.s12),
                    MoneyText(
                      task.reward,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ];
      },
    );

    return RefreshOnForeground(
      tab: ParentTab.review,
      onRefresh: refresh,
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.navToCheck,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: Space.s16),
                ...body,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
