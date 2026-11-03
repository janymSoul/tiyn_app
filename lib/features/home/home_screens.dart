import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/coin_badge.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/presentation/join_teen_screen.dart';
import 'package:tiyn_app/features/family/presentation/parent_code_screen.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (user.role == Role.parent) {
      return ParentCodeScreen(joinCode: user.joinCode ?? '');
    }
    final family = ref.watch(familyControllerProvider);
    final linked = family.value?.isNotEmpty ?? false;
    return linked ? _TeenHomePlaceholder(user: user) : const JoinTeenScreen();
  }
}

class _TeenHomePlaceholder extends ConsumerWidget {
  const _TeenHomePlaceholder({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final parents = ref.watch(familyControllerProvider).value ?? const [];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hi, ${user.displayName}',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),
              const CoinBadge(size: 180, glyph: '0 ₸'),
              const SizedBox(height: 24),
              Text(
                'Connected to ${parents.map((p) => p.displayName).join(', ')}',
                style: text.bodyMedium?.copyWith(color: Palette.muted),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
