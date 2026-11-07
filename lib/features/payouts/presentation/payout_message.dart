import 'package:flutter/material.dart';
import 'package:tiyn_app/design/tokens.dart';

/// A title with an optional sentence under it, scrollable so a pull-to-refresh
/// still works. Used for outcomes and "no longer available" on both roles'
/// payout screens.
class PayoutMessage extends StatelessWidget {
  const PayoutMessage({required this.title, this.body, super.key});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: Space.s12),
          Text(
            body!,
            style: text.bodyLarge?.copyWith(color: Palette.muted, height: 1.5),
          ),
        ],
      ],
    );
  }
}
