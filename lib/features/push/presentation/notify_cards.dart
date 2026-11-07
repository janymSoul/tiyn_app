import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/core/push/notification_settings_opener.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/app_card.dart';
import 'package:tiyn_app/features/push/application/push_prompt.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// The single "notifications are off" card on a home screen, for either role,
/// after the system dialog was refused. It never comes back once dismissed.
/// (The first ask is a bottom sheet, not a card: see `notify_prompt_sheet`.)
class NotifyCards extends ConsumerWidget {
  const NotifyCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompt = ref.watch(pushPromptProvider);
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(pushPromptProvider.notifier);

    if (prompt.showDeniedCard) {
      return _CardFrame(
        child: _CardBody(
          title: l10n.notifyDeniedTitle,
          body: l10n.notifyDeniedBody,
          primaryLabel: l10n.notifyOpenSettings,
          onPrimary: () => ref.read(notificationSettingsOpenerProvider).open(),
          secondaryLabel: l10n.notifyDismiss,
          onSecondary: controller.dismissDeniedCard,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.s16),
    child: AppCard(child: child),
  );
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.title,
    this.body,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final String title;
  final String? body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final body = this.body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: Space.s4),
          Text(body, style: text.bodyMedium?.copyWith(color: Palette.muted)),
        ],
        const SizedBox(height: Space.s8),
        Wrap(
          spacing: Space.s8,
          runSpacing: Space.s4,
          children: [
            FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
            TextButton(onPressed: onSecondary, child: Text(secondaryLabel)),
          ],
        ),
      ],
    );
  }
}
