import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api_error.dart';
import '../../core/theme.dart';
import 'family_controller.dart';

class ParentCodeScreen extends ConsumerWidget {
  const ParentCodeScreen({super.key, required this.joinCode});

  final String joinCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
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
                'Connect your teen',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ask your teen to open Tiyn, choose Teen, and type this code. Then you can give them tasks.',
                style: text.bodyMedium?.copyWith(
                  color: Palette.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      'Your code',
                      style: text.bodyMedium?.copyWith(color: Palette.muted),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      joinCode,
                      style: text.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'It never changes. Share it only with your family.',
                      textAlign: TextAlign.center,
                      style: text.bodySmall?.copyWith(color: Palette.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(
                          text: 'Join me on Tiyn. My family code is $joinCode',
                        ),
                      ),
                      child: const Text('Send code'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: joinCode));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied')),
                          );
                        }
                      },
                      child: const Text('Copy'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Linked teens',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              family.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _Panel(
                  child: Text(
                    e is ApiException
                        ? 'Could not load your teens (${e.code}). Pull down to retry.'
                        : 'Could not load your teens. Pull down to retry.',
                    style: text.bodyMedium?.copyWith(
                      color: Palette.warn,
                      height: 1.5,
                    ),
                  ),
                ),
                data: (members) => members.isEmpty
                    ? _Panel(
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Nobody yet. Pull down to refresh once your teen enters the code.',
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
                              child: _Panel(
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
                                    const SizedBox(width: 12),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
