// crayon_widgets.dart
// Reusable wrapper widgets implementing the hand-drawn crayon storybook look.
// Exports: CrayonCard, CrayonChip, CrayonCircle, CrayonButton, PaperBackground.
// All existing screens/widgets import these to replace standard Material components.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'crayon_painters.dart';
import 'crayon_theme.dart';

// ─── Paper Background ───────────────────────────────────────────────────────
/// Wraps the entire app in a paper-texture background.
/// Used via MaterialApp.router(builder:) so it covers every route.
class PaperBackground extends StatelessWidget {
  final Widget child;
  const PaperBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: const PaperTexturePainter()),
        ),
        child,
      ],
    );
  }
}

// ─── CrayonCard ─────────────────────────────────────────────────────────────
/// Replaces Card throughout the app. Renders a wobbly-bordered paper note.
/// [seed] should be set to a stable value (e.g. index) for consistent wobble.
class CrayonCard extends StatelessWidget {
  final Widget child;
  final Color? fillColor;
  final Color? strokeColor;
  final EdgeInsetsGeometry padding;
  final double cornerRadius;
  final int seed;
  /// Slight random tilt in degrees (0 = no tilt). Adds a "stuck-on" feel.
  final bool enableTilt;

  const CrayonCard({
    super.key,
    required this.child,
    this.fillColor,
    this.strokeColor,
    this.padding = const EdgeInsets.all(12),
    this.cornerRadius = 12,
    this.seed = 0,
    this.enableTilt = false,
  });

  @override
  Widget build(BuildContext context) {
    final fill   = fillColor   ?? CrayonColors.surface;
    final stroke = strokeColor ?? CrayonColors.strokeLight;

    // Small deterministic tilt (±1.2°) for the "stuck note" feel
    final tiltDeg = enableTilt
        ? (math.Random(seed * 7 + 3).nextDouble() - 0.5) * 2.4
        : 0.0;

    Widget card = CustomPaint(
      painter: WobblyRectPainter(
        fillColor: fill,
        strokeColor: stroke,
        cornerRadius: cornerRadius,
        seed: seed,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (tiltDeg != 0) {
      card = Transform.rotate(
        angle: tiltDeg * math.pi / 180,
        child: card,
      );
    }

    return card;
  }
}

// ─── CrayonChip ─────────────────────────────────────────────────────────────
/// Replaces label badges and filter chips with a wobbly pill shape.
class CrayonChip extends StatelessWidget {
  final Widget child;
  final Color fillColor;
  final Color strokeColor;
  final EdgeInsetsGeometry padding;
  final int seed;

  const CrayonChip({
    super.key,
    required this.child,
    required this.fillColor,
    required this.strokeColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.seed = 0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WobblyRectPainter(
        fillColor: fillColor,
        strokeColor: strokeColor,
        cornerRadius: 20, // pill shape
        strokeWidth: 1.5,
        seed: seed,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

// ─── CrayonCircle ────────────────────────────────────────────────────────────
/// Replaces BoxShape.circle containers (score badges, avatars).
class CrayonCircle extends StatelessWidget {
  final Widget child;
  final Color fillColor;
  final Color strokeColor;
  final double size;
  final int seed;

  const CrayonCircle({
    super.key,
    required this.child,
    required this.fillColor,
    required this.strokeColor,
    this.size = 44,
    this.seed = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: WobblyCirclePainter(
          fillColor: fillColor,
          strokeColor: strokeColor,
          seed: seed,
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ─── CrayonButton ────────────────────────────────────────────────────────────
/// A FAB-style button with wobbly border and hand-written label.
class CrayonButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final int seed;

  const CrayonButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.seed = 99,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? CrayonColors.accentPurple;
    final fg = foregroundColor ?? CrayonColors.textPrimary;

    return GestureDetector(
      onTap: onPressed,
      child: CrayonCard(
        fillColor: bg,
        strokeColor: fg.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        cornerRadius: 28,
        seed: seed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.caveat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CrayonSectionHeader ─────────────────────────────────────────────────────
/// A section heading in the crayon storybook style.
class CrayonSectionHeader extends StatelessWidget {
  final String title;
  const CrayonSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.caveat(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: CrayonColors.textPrimary,
        ),
      ),
    );
  }
}
