import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/features/push/application/push_prompt.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// The parent's one-time ask, right after a task or milestone is created
/// (`Get notified when {name} sends proof`). Our own explanation first, then
/// the system dialog if they accept.
///
/// Takes a [container] and the root navigator's context, not a `WidgetRef`:
/// it runs after the create form has closed, so that screen's ref is gone.
Future<void> askForNotificationsAfterCreate({
  required BuildContext navigatorContext,
  required ProviderContainer container,
  String? teenName,
}) async {
  if (!container.read(pushPromptProvider).shouldAsk) return;
  final controller = container.read(pushPromptProvider.notifier);
  await controller.markExplained();
  await SchedulerBinding.instance.endOfFrame;
  if (!navigatorContext.mounted) return;
  final accepted = await showModalBottomSheet<bool>(
    context: navigatorContext,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _NotifySheet(teenName: teenName),
  );
  if (accepted ?? false) await controller.turnOn();
}

class _NotifySheet extends StatelessWidget {
  const _NotifySheet({this.teenName});

  final String? teenName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Space.s24,
          Space.s4,
          Space.s24,
          Space.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.notifyParentSheetTitle(
                  teenName ?? l10n.notifyFallbackName,
                ),
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: Space.s8),
            Text(
              l10n.notifyParentSheetBody,
              style: text.bodyMedium?.copyWith(color: Palette.muted),
            ),
            const SizedBox(height: Space.s24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.notifyTurnOn),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.notifyNotNow),
            ),
          ],
        ),
      ),
    );
  }
}
