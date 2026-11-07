import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/design/widgets/app_card.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// The parent's code with Send and Copy. On the empty home it is the page; the
/// rest of the time it lives in the "Add a teen" sheet.
class JoinCodePanel extends StatelessWidget {
  const JoinCodePanel({super.key, required this.joinCode});

  final String joinCode;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
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
                joinCode,
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
                  ShareParams(text: l10n.parentCodeShareMessage(joinCode)),
                ),
                child: Text(l10n.parentCodeSend),
              ),
            ),
            const SizedBox(width: Space.s12),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: joinCode));
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
      ],
    );
  }
}
