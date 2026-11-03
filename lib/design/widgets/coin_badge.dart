import 'package:flutter/material.dart';
import 'package:tiyn_app/design/tokens.dart';

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
