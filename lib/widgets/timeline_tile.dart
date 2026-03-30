// timeline_tile.dart
// Renders a single event in the per-friend timeline.
// Draws a vertical connector line on the left and a colored dot.
// InteractionTimelineEvent: green/grey/red dot with score + note.
// LabelChangeTimelineEvent: indigo dot with from → to label transition.
// PeriodDividerTile: full-width chapter header (rendered separately, not via TimelineTile).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/timeline_event.dart';
import '../utils/constants.dart';
import '../widgets/label_badge.dart';

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
                // Top line (hidden for first item)
                Expanded(
                  child: Center(
                    child: Container(
                      width: 2,
                      color: isFirst ? Colors.transparent : Colors.grey.shade300,
                    ),
                  ),
                ),
                // Dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _dotColor,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _dotColor.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                // Bottom line (hidden for last item)
                Expanded(
                  child: Center(
                    child: Container(
                      width: 2,
                      color: isLast ? Colors.transparent : Colors.grey.shade300,
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
                PeriodDividerTimelineEvent _ => const SizedBox.shrink(), // never rendered here
              },
            ),
          ),
        ],
      ),
    );
  }

  Color get _dotColor {
    return switch (event) {
      InteractionTimelineEvent e => e.interaction.score > 0
          ? const Color(0xFF2E7D32)
          : e.interaction.score < 0
              ? const Color(0xFFC62828)
              : Colors.grey,
      LabelChangeTimelineEvent _ => Colors.indigo,
      PeriodDividerTimelineEvent _ => Colors.transparent, // never rendered via TimelineTile
    };
  }
}

class _InteractionContent extends StatelessWidget {
  final InteractionTimelineEvent event;
  const _InteractionContent({required this.event});

  Color get _scoreColor {
    final s = event.interaction.score;
    if (s > 0) return const Color(0xFF2E7D32);
    if (s < 0) return const Color(0xFFC62828);
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final i = event.interaction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _scoreColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                i.score > 0 ? '+${i.score}' : '${i.score}',
                style: TextStyle(
                  color: _scoreColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                scoreDescriptions[i.score] ?? '',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        if (i.note != null && i.note!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            i.note!,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          DateFormat('MMM d, yyyy').format(i.createdAt.toLocal()),
          style: const TextStyle(fontSize: 11, color: Colors.grey),
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
            ),
            LabelBadge(label: c.toLabel, small: true),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                c.triggeredBy.name == 'manual' ? 'Manual' : 'System',
                style: const TextStyle(fontSize: 10, color: Colors.indigo),
              ),
            ),
          ],
        ),
        if (c.reason != null && c.reason!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '"${c.reason}"',
            style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.black54),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          DateFormat('MMM d, yyyy').format(c.createdAt.toLocal()),
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

/// Full-width chapter divider shown between label-change periods.
/// Displays the label name as a styled chip with date range and interaction stats.
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
        ? const Color(0xFF2E7D32)
        : avg < 0
            ? const Color(0xFFC62828)
            : Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: LabelBadge(label: event.label),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateRange,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          if (event.interactionCount > 0) ...[
            const SizedBox(height: 2),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                children: [
                  TextSpan(
                    text:
                        '${event.interactionCount} interaction${event.interactionCount == 1 ? '' : 's'} · avg ',
                  ),
                  TextSpan(
                    text: avgText,
                    style: TextStyle(
                        color: avgColor, fontWeight: FontWeight.w600),
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
