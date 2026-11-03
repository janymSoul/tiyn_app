import 'package:flutter/material.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/coin_badge.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.hasError = false, this.onRetry});

  final bool hasError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Palette.navy,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CoinBadge(size: 132, glyph: '₸', ring: Palette.ringOnNavy),
              const SizedBox(height: 32),
              if (hasError) ...[
                Text(
                  l10n.splashLoadFailed,
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(
                    color: Palette.onNavyMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: Palette.gold,
                    foregroundColor: Palette.navy,
                  ),
                  child: Text(l10n.actionTryAgain),
                ),
              ] else
                const CircularProgressIndicator(color: Palette.gold),
            ],
          ),
        ),
      ),
    );
  }
}
