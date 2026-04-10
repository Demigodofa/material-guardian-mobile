import 'package:flutter/material.dart';

ThemeData buildMaterialGuardianTheme() {
  const screenBackground = Color(0xFFF1F3F6);
  const cardBackground = Color(0xFFF8FAFC);
  const divider = Color(0xFFCDD4DE);
  const primaryButton = Color(0xFF22324A);
  const primaryButtonText = Color(0xFFF2F4F7);
  const primaryContainer = Color(0xFFD9E5F2);
  const onPrimaryContainer = Color(0xFF17212F);
  const exportButton = Color(0xFF1C3F5B);
  const secondaryContainer = Color(0xFFE3ECF4);
  const onSecondaryContainer = Color(0xFF17212F);
  const textPrimary = Color(0xFF1F2937);
  const textSecondary = Color(0xFF566173);
  const deleteButton = Color(0xFFB00020);
  const deleteButtonText = Color(0xFFFFFFFF);
  const deleteContainer = Color(0xFFC01833);
  const onDeleteContainer = Color(0xFFFFF4F6);

  const scheme = ColorScheme.light(
    primary: primaryButton,
    onPrimary: primaryButtonText,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: exportButton,
    onSecondary: Colors.white,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    surface: cardBackground,
    onSurface: textPrimary,
    error: deleteButton,
    onError: deleteButtonText,
    errorContainer: deleteContainer,
    onErrorContainer: onDeleteContainer,
    outline: divider,
    outlineVariant: divider,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: screenBackground,
    canvasColor: screenBackground,
    dividerColor: divider,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    dividerTheme: const DividerThemeData(color: divider, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardBackground,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
    ),
    cardTheme: CardThemeData(
      color: cardBackground,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: divider),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryButton,
        foregroundColor: primaryButtonText,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: cardBackground,
        foregroundColor: exportButton,
        side: const BorderSide(color: divider),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: exportButton),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: cardBackground,
      selectedColor: primaryButton,
      side: const BorderSide(color: divider),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: const TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: const TextStyle(
        color: primaryButtonText,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: textPrimary),
      bodyMedium: TextStyle(color: textSecondary),
      labelLarge: TextStyle(fontWeight: FontWeight.w600),
    ),
  );
}
