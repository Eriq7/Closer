// relationship_graph_painter.dart
// CustomPainter that draws a concentric-circle relationship map.
// Center = user ("You"). 4 rings = Active / Responsive / Obligatory / Cut-off.
// Crayon storybook style: slightly wobbly ring paths, pastel fills, Caveat-like text.

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/friend.dart';
import '../utils/constants.dart';
import '../theme/crayon_theme.dart';

/// Holds the computed screen position of a friend node, used for tap detection.
class FriendNode {
  final Friend friend;
  final Offset center;
  const FriendNode({required this.friend, required this.center});
}

class RelationshipGraphPainter extends CustomPainter {
  final List<Friend> friends;
  final String userName;

  static const _ringFractions = [0.25, 0.50, 0.72, 0.92];

  static const _labelRingIndex = {
    RelationshipLabel.active: 0,
    RelationshipLabel.responsive: 1,
    RelationshipLabel.obligatory: 2,
    RelationshipLabel.cutOff: 3,
  };

  final List<FriendNode> _nodes = [];

  RelationshipGraphPainter({required this.friends, required this.userName});

  @override
  void paint(Canvas canvas, Size size) {
    _nodes.clear();
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = min(size.width, size.height) / 2 - 24;

    // Draw ring fills and borders (slightly wobbly circles).
    for (int i = _ringFractions.length - 1; i >= 0; i--) {
      final r = maxR * _ringFractions[i];
      final label = _labelRingIndex.entries.firstWhere((e) => e.value == i).key;
      final colors = labelCrayonColors(label);

      // Wobbly fill circle
      canvas.drawPath(
        _wobblyCirclePath(center, r, seed: i * 13 + 7),
        Paint()..color = colors.fill.withAlpha(25),
      );
      // Wobbly stroke circle
      canvas.drawPath(
        _wobblyCirclePath(center, r, seed: i * 13 + 7),
        Paint()
          ..color = colors.border.withAlpha(70)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Draw ring labels.
    for (final entry in _labelRingIndex.entries) {
      final r = maxR * _ringFractions[entry.value];
      final colors = labelCrayonColors(entry.key);
      _drawText(
        canvas,
        entry.key.displayName,
        Offset(center.dx + r - 4, center.dy - 10),
        color: colors.text.withAlpha(160),
        fontSize: 13,
        align: TextAlign.right,
      );
    }

    // Place friend nodes on their ring.
    final grouped = <RelationshipLabel, List<Friend>>{};
    for (final label in RelationshipLabel.values) {
      grouped[label] = friends.where((f) => f.label == label).toList();
    }

    for (final entry in grouped.entries) {
      final ringIdx = _labelRingIndex[entry.key]!;
      final r = maxR * _ringFractions[ringIdx];
      final count = entry.value.length;
      if (count == 0) continue;

      final colors = labelCrayonColors(entry.key);

      for (int i = 0; i < count; i++) {
        final angle = (2 * pi / count) * i - pi / 2;
        final nodeCenter = Offset(
          center.dx + r * cos(angle),
          center.dy + r * sin(angle),
        );
        final friend = entry.value[i];
        final seed = friend.name.hashCode & 0xFF;

        // Wobbly node circle fill
        canvas.drawPath(
          _wobblyCirclePath(nodeCenter, 14, seed: seed),
          Paint()..color = colors.fill.withAlpha(70),
        );
        canvas.drawPath(
          _wobblyCirclePath(nodeCenter, 14, seed: seed),
          Paint()
            ..color = colors.border.withAlpha(160)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );

        // Initial letter
        _drawText(
          canvas,
          friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
          nodeCenter - const Offset(0, 7),
          color: colors.text,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        );

        // Name below node
        _drawText(
          canvas,
          friend.name,
          Offset(nodeCenter.dx, nodeCenter.dy + 18),
          color: CrayonColors.textSecondary,
          fontSize: 12,
        );

        _nodes.add(FriendNode(friend: friend, center: nodeCenter));
      }
    }

    // Center "You" bubble
    canvas.drawPath(
      _wobblyCirclePath(center, 28, seed: 99),
      Paint()..color = CrayonColors.accentPurple.withAlpha(40),
    );
    canvas.drawPath(
      _wobblyCirclePath(center, 28, seed: 99),
      Paint()
        ..color = CrayonColors.accentPurple.withAlpha(120)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _drawText(
      canvas,
      userName.isNotEmpty ? userName.split(' ').first : 'You',
      center - const Offset(0, 7),
      color: CrayonColors.accentPurple.withAlpha(200),
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );
  }

  /// Builds a slightly wobbly circle path centered at [center] with radius [r].
  Path _wobblyCirclePath(Offset center, double r, {int seed = 0}) {
    final rng = Random(seed);
    const steps = 24;
    final path = Path();

    for (int i = 0; i <= steps; i++) {
      final angle = (i / steps) * 2 * pi;
      final noise = (rng.nextDouble() - 0.5) * r * 0.07;
      final rr = r + noise;
      final pt = Offset(
        center.dx + rr * cos(angle),
        center.dy + rr * sin(angle),
      );
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    return path;
  }

  Friend? findFriendAt(Offset tapPosition) {
    for (final node in _nodes) {
      if ((tapPosition - node.center).distance <= 20) {
        return node.friend;
      }
    }
    return null;
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset topCenter, {
    Color color = const Color(0xFF555555),
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    TextAlign align = TextAlign.center,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: 'Caveat',
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 72);

    tp.paint(canvas, topCenter - Offset(tp.width / 2, 0));
  }

  @override
  bool shouldRepaint(RelationshipGraphPainter old) =>
      old.friends != friends || old.userName != userName;
}
