// label_badge.dart
// Colored chip/badge that displays a relationship label.
// Now uses CrayonChip for a hand-drawn sticker look.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../theme/crayon_theme.dart';
import '../theme/crayon_widgets.dart';

class LabelBadge extends StatelessWidget {
  final RelationshipLabel label;
  final bool small;

  const LabelBadge({super.key, required this.label, this.small = false});

  @override
  Widget build(BuildContext context) {
    final colors = labelCrayonColors(label);
    final seed = label.index * 17 + 5; // stable deterministic seed per label

    return CrayonChip(
      fillColor: colors.fill,
      strokeColor: colors.border,
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      seed: seed,
      child: Text(
        label.displayName,
        style: GoogleFonts.caveat(
          color: colors.text,
          fontSize: small ? 13 : 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
