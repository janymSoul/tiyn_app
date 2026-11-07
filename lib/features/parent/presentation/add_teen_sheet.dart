import 'package:flutter/material.dart';
import 'package:tiyn_app/design/tokens.dart';
import 'package:tiyn_app/features/family/presentation/join_code_panel.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

Future<void> showAddTeenSheet(
  BuildContext context, {
  required String joinCode,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
    ),
    builder: (_) => AddTeenSheet(joinCode: joinCode),
  );
}

class AddTeenSheet extends StatelessWidget {
  const AddTeenSheet({super.key, required this.joinCode});

  final String joinCode;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.addTeenTitle,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: Space.s8),
            Text(
              l10n.parentCodeSubtitle,
              style: text.bodyMedium?.copyWith(
                color: Palette.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: Space.s20),
            JoinCodePanel(joinCode: joinCode),
          ],
        ),
      ),
    );
  }
}
