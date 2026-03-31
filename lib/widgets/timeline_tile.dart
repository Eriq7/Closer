// timeline_tile.dart
// Renders a single event in the per-friend timeline.
// Draws a vertical connector line on the left and a colored dot.
// Uses crayon storybook style: wobbly chips, pastel colors, hand-drawn lines.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/timeline_event.dart';
import '../utils/constants.dart';
import '../widgets/label_badge.dart';
import '../theme/crayon_theme.dart';
import '../theme/crayon_widgets.dart';

class TimelineTile extends StatelessWidget {
  final TimelineEvent event;
  final bool isFirst;
  final bool isLast;

  const TimelineTile({
    super.key,
    required this.event,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: line + dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Top line
                Expanded(
                  child: Center(
                    child: isFirst
                        ? const SizedBox(width: 2)
                        : CustomPaint(
                            painter: _WobblyLinePainter(
                              color: CrayonColors.strokeLight,
                            ),
                            size: const Size(2, double.infinity),
                          ),
                  ),
                ),
                // Dot
                CrayonCircle(
                  fillColor: _dotFill,
                  strokeColor: _dotFill.withValues(alpha: 0.7),
                  size: 14,
                  seed: event.hashCode & 0xFF,
                  child: const SizedBox.shrink(),
                ),
                // Bottom line
                Expanded(
                  child: Center(
                    child: isLast
                        ? const SizedBox(width: 2)
                        : CustomPaint(
                            painter: _WobblyLinePainter(
                              color: CrayonColors.strokeLight,
                            ),
                            size: const Size(2, double.infinity),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right: content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: switch (event) {
                InteractionTimelineEvent e => _InteractionContent(event: e),
                LabelChangeTimelineEvent e => _LabelChangeContent(event: e),
                PeriodDividerTimelineEvent _ => const SizedBox.shrink(),
              },
            ),
          ),
        ],
      ),
    );
  }

  Color get _dotFill {
    return switch (event) {
      InteractionTimelineEvent e => e.interaction.score > 0
          ? CrayonColors.scorePositive1
          : e.interaction.score < 0
              ? CrayonColors.scoreNegative1
              : CrayonColors.scoreNeutral,
      LabelChangeTimelineEvent _ => CrayonColors.accentPurple,
      PeriodDividerTimelineEvent _ => Colors.transparent,
    };
  }
}

/// Simple wavy vertical line painter for the timeline connector.
class _WobblyLinePainter extends CustomPainter {
  final Color color;
  const _WobblyLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height < 1) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    const steps = 8;
    final stepH = size.height / steps;
    path.moveTo(size.width / 2, 0);

    for (int i = 1; i <= steps; i++) {
      final x = size.width / 2 + math.sin(i * 1.8) * 1.2;
      final y = stepH * i;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WobblyLinePainter old) => old.color != color;
}

class _InteractionContent extends StatelessWidget {
  final InteractionTimelineEvent event;
  const _InteractionContent({required this.event});

  @override
  Widget build(BuildContext context) {
    final i = event.interaction;
    final fill = scoreFillColor(i.score);
    final textCol = scoreTextColor(i.score);
    final label = i.score > 0 ? '+${i.score}' : '${i.score}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CrayonChip(
              fillColor: fill.withValues(alpha: 0.3),
              strokeColor: fill,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              seed: i.score + 50,
              child: Text(
                label,
                style: GoogleFonts.caveat(
                  color: textCol,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                scoreDescriptions[i.score] ?? '',
                style: GoogleFonts.caveat(
                  fontSize: 17,
                  color: CrayonColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        if (i.note != null && i.note!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            i.note!,
            style: GoogleFonts.caveat(
              fontSize: 16,
              color: CrayonColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          DateFormat('MMM d, yyyy').format(i.createdAt.toLocal()),
          style: GoogleFonts.caveat(fontSize: 15, color: CrayonColors.textHint),
        ),
      ],
    );
  }
}

class _LabelChangeContent extends StatelessWidget {
  final LabelChangeTimelineEvent event;
  const _LabelChangeContent({required this.event});

  @override
  Widget build(BuildContext context) {
    final c = event.change;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            LabelBadge(label: c.fromLabel, small: true),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: PhosphorIcon(
                PhosphorIconsThin.arrowRight,
                size: 14,
                color: CrayonColors.textSecondary,
              ),
            ),
            LabelBadge(label: c.toLabel, small: true),
            const SizedBox(width: 8),
            CrayonChip(
              fillColor: CrayonColors.accentPurple.withValues(alpha: 0.15),
              strokeColor: CrayonColors.accentPurple.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              seed: 77,
              child: Text(
                c.triggeredBy.name == 'manual' ? 'Manual' : 'System',
                style: GoogleFonts.caveat(
                  fontSize: 14,
                  color: CrayonColors.accentPurple.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
        if (c.reason != null && c.reason!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '"${c.reason}"',
            style: GoogleFonts.caveat(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: CrayonColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          DateFormat('MMM d, yyyy').format(c.createdAt.toLocal()),
          style: GoogleFonts.caveat(fontSize: 15, color: CrayonColors.textHint),
        ),
      ],
    );
  }
}

/// Full-width chapter divider shown between label-change periods.
class PeriodDividerTile extends StatelessWidget {
  final PeriodDividerTimelineEvent event;

  const PeriodDividerTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM yyyy');
    final startStr =
        event.start == null ? 'Beginning' : fmt.format(event.start!.toLocal());
    final endStr =
        event.end == null ? 'Ongoing' : fmt.format(event.end!.toLocal());
    final dateRange = '$startStr – $endStr';

    final avg = event.averageScore;
    final avgText = avg >= 0
        ? '+${avg.toStringAsFixed(1)}'
        : avg.toStringAsFixed(1);
    final avgColor = avg > 0
        ? CrayonColors.activeLabelText
        : avg < 0
            ? Color(0xFF8B2A2A)
            : CrayonColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Divider(color: CrayonColors.strokeLight)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: LabelBadge(label: event.label),
              ),
              Expanded(child: Divider(color: CrayonColors.strokeLight)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateRange,
            style: GoogleFonts.caveat(
              fontSize: 15,
              color: CrayonColors.textHint,
            ),
          ),
          if (event.interactionCount > 0) ...[
            const SizedBox(height: 2),
            RichText(
              text: TextSpan(
                style: GoogleFonts.caveat(
                  fontSize: 15,
                  color: CrayonColors.textHint,
                ),
                children: [
                  TextSpan(
                    text:
                        '${event.interactionCount} interaction${event.interactionCount == 1 ? '' : 's'} · avg ',
                  ),
                  TextSpan(
                    text: avgText,
                    style: TextStyle(
                      color: avgColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
