import 'package:flutter/material.dart';
import 'package:tiyn_app/design/tokens.dart';

class BusyButton extends StatelessWidget {
  const BusyButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.busy = false,
    this.outlined = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool busy;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final content = busy
        ? SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: outlined ? Palette.navy : Colors.white,
            ),
          )
        : child;
    final handler = busy ? null : onPressed;
    return outlined
        ? OutlinedButton(onPressed: handler, child: content)
        : FilledButton(onPressed: handler, child: content);
  }
}
