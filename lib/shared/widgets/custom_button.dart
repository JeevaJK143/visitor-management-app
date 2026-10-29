import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool outlined;
  final Color? color;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.outlined = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    final leading = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: outlined ? color : Colors.white,
            ),
          )
        : (icon == null ? null : Icon(icon, color: outlined ? color : null));

    final text = Text(
      label,
      style: outlined && color != null ? TextStyle(color: color) : null,
    );

    if (outlined) {
      return OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: leading ?? const SizedBox.shrink(),
        label: text,
        style: color == null
            ? null
            : OutlinedButton.styleFrom(
                side: BorderSide(color: color!),
              ),
      );
    }

    return FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: leading ?? const SizedBox.shrink(),
      label: text,
      style: color == null
          ? null
          : FilledButton.styleFrom(backgroundColor: color),
    );
  }
}
