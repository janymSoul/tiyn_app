import 'package:flutter/material.dart';
import 'package:tiyn_app/design/tokens.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.large = false,
    this.padding = const EdgeInsets.all(Space.s16),
  });

  final Widget child;
  final bool large;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          large ? Radii.cardLarge : Radii.card,
        ),
      ),
      child: child,
    );
  }
}
