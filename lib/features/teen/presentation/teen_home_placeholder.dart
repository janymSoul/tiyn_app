import 'package:flutter/material.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/coin_badge.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

class TeenHomePlaceholder extends StatelessWidget {
  const TeenHomePlaceholder({
    super.key,
    required this.displayName,
    required this.parentNames,
    required this.onSignOut,
  });

  final String displayName;
  final List<String> parentNames;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.teenGreeting(displayName),
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),
              const CoinBadge(size: 180, glyph: '0 ₸'),
              const SizedBox(height: 24),
              Text(
                l10n.teenConnectedTo(parentNames.join(', ')),
                style: text.bodyMedium?.copyWith(color: Palette.muted),
              ),
              const Spacer(),
              TextButton(onPressed: onSignOut, child: Text(l10n.actionSignOut)),
            ],
          ),
        ),
      ),
    );
  }
}
