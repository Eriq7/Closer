// crayon_painters.dart
// Custom painters for the hand-drawn crayon storybook visual effects.
// Exports: WobblyRectPainter, WobblyCirclePainter, PaperTexturePainter.
// All shapes use sin-wave path perturbation with a deterministic seed
// so they look consistent across rebuilds (no jitter).

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─── Wobbly Rectangle Border Painter ───────────────────────────────────────
/// Paints a rounded-rect with slightly wobbly edges and filled background,
/// mimicking a hand-drawn crayon shape.
class WobblyRectPainter extends CustomPainter {
  final Color fillColor;
  final Color strokeColor;
  final double cornerRadius;
  final double strokeWidth;
  final int seed;

  // Cached path so we only recompute on size change.
  Path? _cachedPath;
  Size? _cachedSize;

  WobblyRectPainter({
    required this.fillColor,
    required this.strokeColor,
    this.cornerRadius = 12.0,
    this.strokeWidth = 1.8,
    this.seed = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (_cachedPath == null || _cachedSize != size) {
      _cachedPath = _buildWobblyPath(size);
      _cachedSize = size;
    }
    final path = _cachedPath!;

    // Fill
    canvas.drawPath(path, Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill);

    // Primary stroke
    canvas.drawPath(path, Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    // Second faint stroke offset slightly — gives crayon double-trace effect
    canvas.drawPath(path, Paint()
      ..color = strokeColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.8
      ..strokeCap = StrokeCap.round);
  }

  Path _buildWobblyPath(Size size) {
    final r = math.min(cornerRadius, math.min(size.width, size.height) / 2);
    final path = Path();
    final rng = math.Random(seed);

    // Helper: build a wobbly segment between two points on the rect edge.
    // `normalDir` is +1 or -1 indicating which side the perturbation bulges.
    List<Offset> wobblyEdge(Offset start, Offset end, int normalAxisIsX) {
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final length = math.sqrt(dx * dx + dy * dy);
      if (length < 1) return [start, end];

      final n = math.max(4, (length / 10).ceil());
      final amplitude = 1.6 + rng.nextDouble() * 0.8; // 1.6–2.4 px
      final freq = 1.2 + rng.nextDouble() * 0.6;       // 1.2–1.8 cycles
      final phase = rng.nextDouble() * math.pi * 2;

      final pts = <Offset>[];
      for (int i = 0; i <= n; i++) {
        final t = i / n;
        final base = Offset(start.dx + dx * t, start.dy + dy * t);
        final perturb = amplitude * math.sin(freq * t * math.pi * 2 + phase);
        pts.add(normalAxisIsX == 1
            ? Offset(base.dx, base.dy + perturb)
            : Offset(base.dx + perturb, base.dy));
      }
      return pts;
    }

    // Corner arc – slightly wobbly radius
    void wobblyArc(Offset center, double startAngle, double radius) {
      // We approximate the quarter-circle arc with 6 points
      final points = <Offset>[];
      const steps = 6;
      for (int i = 0; i <= steps; i++) {
        final angle = startAngle + (math.pi / 2) * (i / steps);
        final r2 = radius + (rng.nextDouble() - 0.5) * 1.2;
        points.add(Offset(
          center.dx + r2 * math.cos(angle),
          center.dy + r2 * math.sin(angle),
        ));
      }
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    // Top edge (left to right, minus corners)
    final topLeft     = Offset(r, 0);
    final topRight    = Offset(size.width - r, 0);
    final rightTop    = Offset(size.width, r);
    final rightBottom = Offset(size.width, size.height - r);
    final bottomRight = Offset(size.width - r, size.height);
    final bottomLeft  = Offset(r, size.height);
    final leftBottom  = Offset(0, size.height - r);
    final leftTop     = Offset(0, r);

    path.moveTo(topLeft.dx, topLeft.dy);

    // Top edge
    for (final pt in wobblyEdge(topLeft, topRight, 1)) {
      path.lineTo(pt.dx, pt.dy);
    }
    // Top-right corner
    wobblyArc(Offset(size.width - r, r), -math.pi / 2, r);
    // Right edge
    for (final pt in wobblyEdge(rightTop, rightBottom, 0)) {
      path.lineTo(pt.dx, pt.dy);
    }
    // Bottom-right corner
    wobblyArc(Offset(size.width - r, size.height - r), 0, r);
    // Bottom edge
    for (final pt in wobblyEdge(bottomRight, bottomLeft, 1)) {
      path.lineTo(pt.dx, pt.dy);
    }
    // Bottom-left corner
    wobblyArc(Offset(r, size.height - r), math.pi / 2, r);
    // Left edge
    for (final pt in wobblyEdge(leftBottom, leftTop, 0)) {
      path.lineTo(pt.dx, pt.dy);
    }
    // Top-left corner
    wobblyArc(Offset(r, r), math.pi, r);

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(WobblyRectPainter old) =>
      old.fillColor != fillColor ||
      old.strokeColor != strokeColor ||
      old.cornerRadius != cornerRadius ||
      old.strokeWidth != strokeWidth ||
      old.seed != seed;
}

// ─── Wobbly Circle Painter ──────────────────────────────────────────────────
/// Paints a slightly irregular circle, like one drawn freehand with crayon.
class WobblyCirclePainter extends CustomPainter {
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final int seed;

  Path? _cachedPath;
  Size? _cachedSize;

  WobblyCirclePainter({
    required this.fillColor,
    required this.strokeColor,
    this.strokeWidth = 1.8,
    this.seed = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (_cachedPath == null || _cachedSize != size) {
      _cachedPath = _buildWobblyCircle(size);
      _cachedSize = size;
    }
    final path = _cachedPath!;

    canvas.drawPath(path, Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill);

    canvas.drawPath(path, Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round);

    canvas.drawPath(path, Paint()
      ..color = strokeColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2.0);
  }

  Path _buildWobblyCircle(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final baseR = math.min(cx, cy) * 0.92;
    final rng = math.Random(seed);

    const steps = 28;
    final path = Path();

    for (int i = 0; i <= steps; i++) {
      final angle = (i / steps) * 2 * math.pi;
      final noise = (rng.nextDouble() - 0.5) * baseR * 0.1;
      final r = baseR + noise;
      final pt = Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(WobblyCirclePainter old) =>
      old.fillColor != fillColor ||
      old.strokeColor != strokeColor ||
      old.strokeWidth != strokeWidth ||
      old.seed != seed;
}

// ─── Paper Texture Painter ──────────────────────────────────────────────────
/// Draws a subtle paper-like texture: warm cream base + low-opacity
/// random noise dots simulating paper fiber grain.
class PaperTexturePainter extends CustomPainter {
  const PaperTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Warm cream base
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFAF3E8),
    );

    // Fiber dots — deterministic via fixed seed for consistent look
    final rng = math.Random(42);
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final dotCount = (size.width * size.height / 400).toInt().clamp(200, 3000);

    for (int i = 0; i < dotCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final opacity = 0.025 + rng.nextDouble() * 0.045; // 2.5–7%
      final radius  = 0.3 + rng.nextDouble() * 0.8;

      // Alternate between warm brown and cool grey fibers
      final isWarm = rng.nextBool();
      dotPaint.color = isWarm
          ? Color.fromRGBO(139, 100, 60, opacity)
          : Color.fromRGBO(100, 90, 80, opacity);

      canvas.drawCircle(Offset(x, y), radius, dotPaint);
    }

    // Occasional longer fiber strokes
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4
      ..strokeCap = StrokeCap.round;
    final lineCount = (dotCount / 15).toInt();

    for (int i = 0; i < lineCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final angle = rng.nextDouble() * math.pi;
      final len   = 3 + rng.nextDouble() * 8;
      linePaint.color = Color.fromRGBO(139, 100, 60, 0.03 + rng.nextDouble() * 0.04);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + math.cos(angle) * len, y + math.sin(angle) * len),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(PaperTexturePainter _) => false; // static texture, never repaint
}
