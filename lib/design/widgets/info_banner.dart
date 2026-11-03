import 'package:flutter/material.dart';
import 'package:tiyn_app/design/tokens.dart';

class InfoBanner extends StatelessWidget {
  const InfoBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Palette.infoWash,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: Palette.infoText, height: 1.5),
      ),
    );
  }
}
