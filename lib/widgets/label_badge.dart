// label_badge.dart
// Colored chip/badge that displays a relationship label.
// Each label has a distinct color to make them easy to scan.

import 'package:flutter/material.dart';
import '../utils/constants.dart';

const Map<RelationshipLabel, Color> labelColors = {
  RelationshipLabel.active: Color(0xFF2E7D32),      // dark green
  RelationshipLabel.responsive: Color(0xFF1565C0),   // dark blue
  RelationshipLabel.obligatory: Color(0xFFE65100),   // dark orange
  RelationshipLabel.cutOff: Color(0xFF616161),        // grey
};

class LabelBadge extends StatelessWidget {
  final RelationshipLabel label;
  final bool small;

  const LabelBadge({super.key, required this.label, this.small = false});

  @override
  Widget build(BuildContext context) {
    final color = labelColors[label]!;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.displayName,
        style: TextStyle(
          color: color,
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
