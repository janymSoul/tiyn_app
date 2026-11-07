import 'package:flutter/material.dart';
import 'package:tiyn_app/design/tokens.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.large = false,
    this.padding = const EdgeInsets.all(Space.s16),
    this.onTap,
  });

  final Widget child;
  final bool large;
  final EdgeInsetsGeometry padding;

  /// Makes the whole card a button with a ripple.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(large ? Radii.cardLarge : Radii.card);
    final onTap = this.onTap;
    if (onTap == null) {
      return Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(color: Colors.white, borderRadius: radius),
        child: child,
      );
    }
    // The ripple is painted by the Material, so the white must be its colour.
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
