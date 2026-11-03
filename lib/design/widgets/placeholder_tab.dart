import 'package:flutter/material.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Center(
                child: Text(
                  AppLocalizations.of(context).comingSoon,
                  style: text.bodyLarge?.copyWith(color: Palette.muted),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
