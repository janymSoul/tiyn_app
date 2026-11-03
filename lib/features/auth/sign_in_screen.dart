import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/api_error.dart';
import '../../core/theme.dart';
import 'auth_controller.dart';
import 'user.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  Role _role = Role.teen;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final busy = auth.isLoading;
    final error = auth.hasError ? _message(auth.error!) : null;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Palette.navy,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CoinBadge(
                        size: 132,
                        glyph: '₸',
                        ring: Palette.ringOnNavy,
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'tiyn',
                        style: text.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Earn it. Save it. Get paid for chores and good grades.',
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(
                          color: Palette.onNavyMuted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Palette.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'I am a',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _RoleCard(
                          title: 'Teen',
                          subtitle: 'I do chores and earn',
                          selected: _role == Role.teen,
                          onTap: busy
                              ? null
                              : () => setState(() => _role = Role.teen),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RoleCard(
                          title: 'Parent',
                          subtitle: 'I set tasks and approve',
                          selected: _role == Role.parent,
                          onTap: busy
                              ? null
                              : () => setState(() => _role = Role.parent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () => ref
                              .read(authControllerProvider.notifier)
                              .signIn(_role),
                    child: busy
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _GoogleG(),
                              SizedBox(width: 10),
                              Text('Continue with Google'),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    error ?? "Your role is saved on first sign-in and can't be changed later.",
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(
                      color: error == null ? Palette.muted : Palette.warn,
                      fontWeight: error == null
                          ? FontWeight.w400
                          : FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _message(Object error) {
    if (error is ApiException) {
      return switch (error.code) {
        'invalid_identity' => 'Google sign-in was rejected. Try again.',
        'identity_provider_unavailable' =>
          'Google is unavailable right now. Try again later.',
        'network_error' => 'No connection. Check your network.',
        _ => 'Sign-in failed (${error.code}).',
      };
    }
    if (error is GoogleSignInException &&
        error.code == GoogleSignInExceptionCode.canceled) {
      return 'Sign-in was cancelled.';
    }
    return 'Sign-in failed. $error';
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Palette.navy : Palette.border,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: text.bodySmall?.copyWith(color: Palette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Palette.navy,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class CoinBadge extends StatelessWidget {
  const CoinBadge({
    super.key,
    required this.size,
    required this.glyph,
    this.ring = Palette.goldSoft,
  });

  final double size;
  final String glyph;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Palette.gold,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: ring, spreadRadius: 5)],
      ),
      child: Text(
        glyph,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: Palette.navy,
        ),
      ),
    );
  }
}
