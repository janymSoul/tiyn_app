import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tiyn_app/core/network/error_messages.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/app_card.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

class ParentCodeScreen extends ConsumerStatefulWidget {
  const ParentCodeScreen({
    super.key,
    required this.joinCode,
    required this.onSignOut,
  });

  final String joinCode;
  final VoidCallback onSignOut;

  @override
  ConsumerState<ParentCodeScreen> createState() => _ParentCodeScreenState();
}

class _ParentCodeScreenState extends ConsumerState<ParentCodeScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // The parent usually leaves the app to send the code and comes back once
    // the teen has joined, so show the new teen without a manual pull.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(familyControllerProvider.notifier).refresh(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final family = ref.watch(familyControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(familyControllerProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
            children: [
              Text(
                l10n.parentCodeTitle,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Space.s8),
              Text(
                l10n.parentCodeSubtitle,
                style: text.bodyMedium?.copyWith(
                  color: Palette.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: Space.s32),
              AppCard(
                large: true,
                padding: const EdgeInsets.symmetric(
                  vertical: Space.s28,
                  horizontal: Space.s16,
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.parentCodeYourCode,
                      style: text.bodyMedium?.copyWith(color: Palette.muted),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      widget.joinCode,
                      style: text.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.parentCodeNeverChanges,
                      textAlign: TextAlign.center,
                      style: text.bodySmall?.copyWith(color: Palette.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.s16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(
                          text: l10n.parentCodeShareMessage(widget.joinCode),
                        ),
                      ),
                      child: Text(l10n.parentCodeSend),
                    ),
                  ),
                  const SizedBox(width: Space.s12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: widget.joinCode),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.parentCodeCopied)),
                          );
                        }
                      },
                      child: Text(l10n.parentCodeCopy),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.s32),
              Text(
                l10n.parentLinkedTeens,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: Space.s8),
              family.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => AppCard(
                  child: Text(
                    '${apiErrorMessage(l10n, e)} ${l10n.pullToRetry}',
                    style: text.bodyMedium?.copyWith(
                      color: Palette.warn,
                      height: 1.5,
                    ),
                  ),
                ),
                data: (members) => members.isEmpty
                    ? AppCard(
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Palette.muted,
                                  width: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: Space.s12),
                            Expanded(
                              child: Text(
                                l10n.parentNoTeensYet,
                                style: text.bodyMedium?.copyWith(
                                  color: Palette.muted,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          for (final m in members)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: AppCard(
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Palette.gold,
                                      child: Text(
                                        m.displayName.isEmpty
                                            ? '?'
                                            : m.displayName[0].toUpperCase(),
                                        style: text.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: Space.s12),
                                    Text(
                                      m.displayName,
                                      style: text.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: Space.s24),
              TextButton(
                onPressed: widget.onSignOut,
                child: Text(l10n.actionSignOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
