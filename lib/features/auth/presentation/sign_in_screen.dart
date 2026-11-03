import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/error_messages.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/busy_button.dart';
import 'package:tiyn_app/design/widgets/coin_badge.dart';
import 'package:tiyn_app/features/auth/application/sign_in_controller.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signInControllerProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Palette.navy,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CoinBadge(
                        size: 132,
                        glyph: '₸',
                        ring: Palette.ringOnNavy,
                      ),
                      const SizedBox(height: Space.s28),
                      Text(
                        'tiyn',
                        style: text.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppLocalizations.of(context).signInTagline,
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
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(Radii.sheet),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: SafeArea(
              top: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (state) {
                  ChoosingRole() => _RoleStep(
                    key: const ValueKey('role'),
                    state: state,
                  ),
                  Welcome() || Authenticating() => _WelcomeStep(
                    key: const ValueKey('welcome'),
                    state: state,
                  ),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _message(AppLocalizations l10n, Object error) {
  if (error is SignInExpired) return l10n.signInExpired;
  if (error is GoogleSignInException) return l10n.signInFailed;
  if (error is ApiException) return apiErrorMessage(l10n, error);
  return l10n.signInFailed;
}

class _WelcomeStep extends ConsumerWidget {
  const _WelcomeStep({super.key, required this.state});

  final SignInState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final error = switch (state) {
      Welcome(:final error?) => _message(l10n, error),
      _ => null,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BusyButton(
          busy: state is Authenticating,
          onPressed: () =>
              ref.read(signInControllerProvider.notifier).continueWithGoogle(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _GoogleG(),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  l10n.signInContinueWithGoogle,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.s16),
        Text(
          error ?? l10n.signInWelcomeNote,
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(
            color: error == null ? Palette.muted : Palette.warn,
            fontWeight: error == null ? FontWeight.w400 : FontWeight.w500,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _RoleStep extends ConsumerWidget {
  const _RoleStep({super.key, required this.state});

  final ChoosingRole state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final controller = ref.read(signInControllerProvider.notifier);
    final error = state.error;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.signInRoleTitle,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: Space.s4),
        Text(
          l10n.signInGoogleAccount(state.credential.email),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.bodySmall?.copyWith(color: Palette.muted),
        ),
        const SizedBox(height: Space.s16),
        Row(
          children: [
            Expanded(
              child: _RoleCard(
                title: l10n.roleTeen,
                subtitle: l10n.roleTeenSubtitle,
                selected: state.selected == Role.teen,
                onTap: state.sending
                    ? null
                    : () => controller.selectRole(Role.teen),
              ),
            ),
            const SizedBox(width: Space.s12),
            Expanded(
              child: _RoleCard(
                title: l10n.roleParent,
                subtitle: l10n.roleParentSubtitle,
                selected: state.selected == Role.parent,
                onTap: state.sending
                    ? null
                    : () => controller.selectRole(Role.parent),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.s16),
        Text(
          l10n.signInRoleNote,
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(
            color: Palette.warn,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: Space.s8),
          Text(
            _message(l10n, error),
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(
              color: Palette.warn,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: Space.s12),
        BusyButton(
          busy: state.sending,
          onPressed: state.selected == null ? null : controller.confirmRole,
          child: Text(l10n.actionContinue),
        ),
        TextButton(
          onPressed: state.sending ? null : controller.useAnotherAccount,
          child: Text(l10n.signInUseAnotherAccount),
        ),
      ],
    );
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
        borderRadius: BorderRadius.circular(Radii.card),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Radii.card),
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
