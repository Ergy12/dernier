import 'package:flutter/material.dart';

class ExpressionInputChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor; // Optional color for the chip's background
  final TextStyle? textStyle; // Optional text style for the label

  const ExpressionInputChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Use a default background color if none is provided, perhaps from the theme
    final Color chipColor = backgroundColor ?? theme.colorScheme.secondary.withOpacity(0.1);
    // Use a default text style if none is provided, perhaps from the theme
    final TextStyle style = textStyle ??
        theme.textTheme.bodySmall!.copyWith(
          color: theme.colorScheme.onSecondaryContainer, // A color that contrasts well with secondary.withOpacity(0.1)
          fontWeight: FontWeight.normal,
        );

    return Chip(
      label: Text(
        label,
        style: style,
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Adjust padding as needed
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0), // Standard chip border radius
        side: BorderSide(
          color: backgroundColor != null ? chipColor.withAlpha(150) : theme.colorScheme.secondary.withOpacity(0.3), // Border color
          width: 1.0,
        ),
      ),
    );
  }
}
