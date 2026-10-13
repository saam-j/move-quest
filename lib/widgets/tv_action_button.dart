import 'package:flutter/material.dart';

class TvActionButton extends StatelessWidget {
  const TvActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.focusNode,
    this.autofocus = false,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(label, maxLines: 1, softWrap: false)),
        const SizedBox(width: 14),
        Icon(icon, size: 25),
      ],
    );

    if (primary) {
      return FilledButton(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: onPressed,
        child: child,
      );
    }
    return OutlinedButton(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      child: child,
    );
  }
}
