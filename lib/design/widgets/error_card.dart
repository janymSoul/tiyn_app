import 'package:flutter/material.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/app_card.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// A plain-language error with a "Try again" button.
class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: Palette.warn, height: 1.5),
          ),
          const SizedBox(height: Space.s8),
          TextButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context).actionTryAgain),
          ),
        ],
      ),
    );
  }
}
