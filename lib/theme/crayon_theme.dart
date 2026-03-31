// crayon_theme.dart
// Central design token system and ThemeData builder for the crayon storybook theme.
// Exports: CrayonColors (design tokens), buildCrayonTheme() (ThemeData).
// All screens and widgets import from here for consistent styling.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────
class CrayonColors {
  CrayonColors._();

  // Backgrounds
  static const Color background = Color(0xFFFAF3E8);   // warm cream paper
  static const Color surface    = Color(0xFFFFF8F0);   // slightly lighter cream for cards
  static const Color surfaceAlt = Color(0xFFF5EDD8);   // a touch darker for contrast

  // Text
  static const Color textPrimary   = Color(0xFF555555);
  static const Color textSecondary = Color(0xFF888888);
  static const Color textHint      = Color(0xFFAAAAAA);

  // Relationship label fills (pastel ice-cream)
  static const Color activeLabel      = Color(0xFF9AE1B5); // mint green
  static const Color responsiveLabel  = Color(0xFFA7C7E7); // sky blue
  static const Color obligatoryLabel  = Color(0xFFFAD7A0); // cream orange
  static const Color cutOffLabel      = Color(0xFFD5D5D5); // soft grey

  // Relationship label text (darker version of fill for readability)
  static const Color activeLabelText      = Color(0xFF2E7D5A);
  static const Color responsiveLabelText  = Color(0xFF2A5F8A);
  static const Color obligatoryLabelText  = Color(0xFF8B5A1A);
  static const Color cutOffLabelText      = Color(0xFF666666);

  // Score badge fills
  static const Color scorePositive2 = Color(0xFF7BC89B); // +2/+3 pastel green
  static const Color scorePositive1 = Color(0xFFA9DFB8); // +1 lighter green
  static const Color scoreNeutral   = Color(0xFFCCCCCC); // 0 light grey
  static const Color scoreNegative1 = Color(0xFFF2C5C5); // -1 light salmon
  static const Color scoreNegative2 = Color(0xFFE88B8B); // -2/-3 deeper salmon

  // Accent
  static const Color accentPurple = Color(0xFFC39BD3); // Log Interaction button
  static const Color warningOrange = Color(0xFFF5CBA7); // warning box

  // Borders / strokes
  static const Color strokeLight  = Color(0xFFD4C5B0);
  static const Color strokeMedium = Color(0xFFB8A898);
}

/// Returns fill and text colors for a given label.
({Color fill, Color text, Color border}) labelCrayonColors(RelationshipLabel label) {
  return switch (label) {
    RelationshipLabel.active     => (fill: CrayonColors.activeLabel,     text: CrayonColors.activeLabelText,     border: Color(0xFF7BC4A0)),
    RelationshipLabel.responsive => (fill: CrayonColors.responsiveLabel, text: CrayonColors.responsiveLabelText, border: Color(0xFF7AAAC8)),
    RelationshipLabel.obligatory => (fill: CrayonColors.obligatoryLabel, text: CrayonColors.obligatoryLabelText, border: Color(0xFFD4A870)),
    RelationshipLabel.cutOff     => (fill: CrayonColors.cutOffLabel,     text: CrayonColors.cutOffLabelText,     border: Color(0xFFAAAAAA)),
  };
}

/// Returns pastel fill color for a given score value.
Color scoreFillColor(int score) {
  if (score >= 2)  return CrayonColors.scorePositive2;
  if (score == 1)  return CrayonColors.scorePositive1;
  if (score == 0)  return CrayonColors.scoreNeutral;
  if (score == -1) return CrayonColors.scoreNegative1;
  return CrayonColors.scoreNegative2;
}

/// Returns text color that contrasts well against the score fill.
Color scoreTextColor(int score) {
  if (score > 0)  return CrayonColors.activeLabelText;
  if (score == 0) return CrayonColors.textSecondary;
  return Color(0xFF8B2A2A);
}

// ─── ThemeData Builder ──────────────────────────────────────────────────────
ThemeData buildCrayonTheme() {
  final base = GoogleFonts.caveatTextTheme(
    ThemeData.light().textTheme,
  );

  // Bump up sizes slightly – Caveat is a display font and reads well larger.
  final textTheme = base.copyWith(
    displayLarge:  base.displayLarge?.copyWith(color: CrayonColors.textPrimary, fontSize: 57),
    displayMedium: base.displayMedium?.copyWith(color: CrayonColors.textPrimary, fontSize: 45),
    displaySmall:  base.displaySmall?.copyWith(color: CrayonColors.textPrimary, fontSize: 36),
    headlineLarge: base.headlineLarge?.copyWith(color: CrayonColors.textPrimary, fontSize: 34),
    headlineMedium:base.headlineMedium?.copyWith(color: CrayonColors.textPrimary, fontSize: 28),
    headlineSmall: base.headlineSmall?.copyWith(color: CrayonColors.textPrimary, fontSize: 24),
    titleLarge:    base.titleLarge?.copyWith(color: CrayonColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
    titleMedium:   base.titleMedium?.copyWith(color: CrayonColors.textPrimary, fontSize: 20),
    titleSmall:    base.titleSmall?.copyWith(color: CrayonColors.textPrimary, fontSize: 17),
    bodyLarge:     base.bodyLarge?.copyWith(color: CrayonColors.textPrimary, fontSize: 18),
    bodyMedium:    base.bodyMedium?.copyWith(color: CrayonColors.textPrimary, fontSize: 16),
    bodySmall:     base.bodySmall?.copyWith(color: CrayonColors.textSecondary, fontSize: 14),
    labelLarge:    base.labelLarge?.copyWith(color: CrayonColors.textPrimary, fontSize: 17),
    labelMedium:   base.labelMedium?.copyWith(color: CrayonColors.textPrimary, fontSize: 15),
    labelSmall:    base.labelSmall?.copyWith(color: CrayonColors.textSecondary, fontSize: 13),
  );

  final colorScheme = ColorScheme.fromSeed(
    seedColor: CrayonColors.accentPurple,
    brightness: Brightness.light,
    surface: CrayonColors.surface,
    onSurface: CrayonColors.textPrimary,
  ).copyWith(
    primary: CrayonColors.accentPurple,
    onPrimary: CrayonColors.textPrimary,
    secondary: CrayonColors.activeLabel,
    onSecondary: CrayonColors.activeLabelText,
    surfaceContainerHighest: CrayonColors.surfaceAlt,
    outline: CrayonColors.strokeLight,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: CrayonColors.textPrimary,
      titleTextStyle: GoogleFonts.caveat(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: CrayonColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: CrayonColors.textPrimary),
    ),
    cardTheme: const CardThemeData(
      color: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: CrayonColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: GoogleFonts.caveat(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: CrayonColors.textPrimary,
      ),
      contentTextStyle: GoogleFonts.caveat(
        fontSize: 16,
        color: CrayonColors.textPrimary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CrayonColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CrayonColors.strokeLight, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CrayonColors.strokeLight, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CrayonColors.strokeMedium, width: 2),
      ),
      labelStyle: GoogleFonts.caveat(color: CrayonColors.textSecondary, fontSize: 17),
      hintStyle:  GoogleFonts.caveat(color: CrayonColors.textHint,      fontSize: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CrayonColors.accentPurple,
        foregroundColor: CrayonColors.textPrimary,
        textStyle: GoogleFonts.caveat(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CrayonColors.accentPurple,
        foregroundColor: CrayonColors.textPrimary,
        textStyle: GoogleFonts.caveat(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: CrayonColors.textSecondary,
        textStyle: GoogleFonts.caveat(fontSize: 16),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: CrayonColors.textSecondary,
    ),
    dividerTheme: const DividerThemeData(
      color: CrayonColors.strokeLight,
      thickness: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: CrayonColors.surface,
      labelStyle: GoogleFonts.caveat(fontSize: 15, color: CrayonColors.textPrimary),
      side: const BorderSide(color: CrayonColors.strokeLight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.all(CrayonColors.accentPurple),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? CrayonColors.accentPurple : Colors.transparent),
      checkColor: WidgetStateProperty.all(Colors.white),
    ),
    iconTheme: const IconThemeData(
      color: CrayonColors.textSecondary,
      size: 22,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: CrayonColors.surfaceAlt,
      contentTextStyle: GoogleFonts.caveat(color: CrayonColors.textPrimary, fontSize: 16),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: CrayonColors.accentPurple,
      foregroundColor: CrayonColors.textPrimary,
      elevation: 2,
    ),
  );
}
