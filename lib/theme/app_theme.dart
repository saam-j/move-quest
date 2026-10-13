import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color background = Color(0xFF071812);
  static const Color forest = Color(0xFF0D241B);
  static const Color surface = Color(0xFF112B21);
  static const Color surfaceElevated = Color(0xFF18392B);
  static const Color lime = Color(0xFFC2F36B);
  static const Color teal = Color(0xFF59D9BC);
  static const Color textPrimary = Color(0xFFF4F6E9);
  static const Color textSecondary = Color(0xFFB1C1B4);
  static const Color outline = Color(0xFF355345);

  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: lime,
      onPrimary: background,
      secondary: teal,
      onSecondary: background,
      surface: surface,
      onSurface: textPrimary,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: textPrimary,
        fontSize: 62,
        fontWeight: FontWeight.w800,
        height: 1.06,
        letterSpacing: -1.3,
      ),
      headlineMedium: TextStyle(
        color: textPrimary,
        fontSize: 43,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.6,
      ),
      titleLarge: TextStyle(
        color: textPrimary,
        fontSize: 27,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(
        color: textSecondary,
        fontSize: 21,
        height: 1.4,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(background),
        backgroundColor: const WidgetStatePropertyAll(lime),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 26, vertical: 14),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
        ),
        side: WidgetStateProperty.resolveWith((states) {
          return BorderSide(
            color: states.contains(WidgetState.focused)
                ? textPrimary
                : lime,
            width: states.contains(WidgetState.focused) ? 3 : 1,
          );
        }),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(textPrimary),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        side: WidgetStateProperty.resolveWith((states) {
          return BorderSide(
            color: states.contains(WidgetState.focused) ? lime : outline,
            width: states.contains(WidgetState.focused) ? 3 : 2,
          );
        }),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      titleTextStyle: const TextStyle(
        color: textPrimary,
        fontSize: 30,
        fontWeight: FontWeight.w800,
      ),
      contentTextStyle: const TextStyle(
        color: textSecondary,
        fontSize: 21,
        height: 1.45,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    useMaterial3: true,
  );
}
