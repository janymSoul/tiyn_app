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
}) => _ask(
  navigatorContext: navigatorContext,
  container: container,
  title: (l10n) =>
      l10n.notifyParentSheetTitle(teenName ?? l10n.notifyFallbackName),
  body: (l10n) => l10n.notifyParentSheetBody,
);

/// The teen's one-time ask, shown on home once they are linked.
Future<void> askTeenForNotifications({
  required BuildContext navigatorContext,
  required ProviderContainer container,
}) => _ask(
  navigatorContext: navigatorContext,
  container: container,
  title: (l10n) => l10n.notifyAskTitleTeen,
  body: (l10n) => l10n.notifyTeenSheetBody,
);

Future<void> _ask({
  required BuildContext navigatorContext,
  required ProviderContainer container,
  required String Function(AppLocalizations) title,
  required String Function(AppLocalizations) body,
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
    builder: (_) => _NotifySheet(title: title, body: body),
  );
  if (accepted ?? false) await controller.turnOn();
}

/// Put on the teen home: asks once, when the prompt state says it is time.
class TeenNotifyPrompt extends ConsumerStatefulWidget {
  const TeenNotifyPrompt({super.key});

  @override
  ConsumerState<TeenNotifyPrompt> createState() => _TeenNotifyPromptState();
}

class _TeenNotifyPromptState extends ConsumerState<TeenNotifyPrompt> {
  bool _asked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAsk());
  }

  void _maybeAsk() {
    if (!mounted || _asked || !ref.read(pushPromptProvider).shouldAsk) return;
    _asked = true;
    unawaited(
      askTeenForNotifications(
        navigatorContext: Navigator.of(context, rootNavigator: true).context,
        container: ProviderScope.containerOf(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pushPromptProvider, (_, next) {
      if (next.shouldAsk) _maybeAsk();
    });
    return const SizedBox.shrink();
  }
}

class _NotifySheet extends StatelessWidget {
  const _NotifySheet({required this.title, required this.body});

  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) body;

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
                title(l10n),
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: Space.s8),
            Text(
              body(l10n),
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
