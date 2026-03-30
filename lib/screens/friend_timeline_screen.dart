// friend_timeline_screen.dart
// Relationship arc dashboard: stats header, score sparkline, and a chronological
// timeline grouped into label-defined chapters (periods).
// Exports: FriendTimelineScreen
// Flow: initState → _load() (parallel fetch) → _buildEventsWithDividers() → build
// Design: PeriodDividerTimelineEvents are synthetic — computed client-side, not stored in DB.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/interaction.dart';
import '../models/label_change.dart';
import '../models/timeline_event.dart';
import '../services/interaction_service.dart';
import '../widgets/timeline_tile.dart';

class FriendTimelineScreen extends StatefulWidget {
  final String friendId;
  final String friendName;

  const FriendTimelineScreen({
    super.key,
    required this.friendId,
    required this.friendName,
  });

  @override
  State<FriendTimelineScreen> createState() => _FriendTimelineScreenState();
}

class _FriendTimelineScreenState extends State<FriendTimelineScreen> {
  final _interactionService = InteractionService();
  List<TimelineEvent> _events = [];
  List<Interaction> _interactions = []; // raw list sorted asc, for sparkline
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Kick off both fetches concurrently.
      final interactionsFuture =
          _interactionService.getInteractionsForFriend(widget.friendId);
      final labelChangesFuture =
          _interactionService.getLabelChangesForFriend(widget.friendId);

      final interactions = await interactionsFuture;
      final labelChanges = await labelChangesFuture;

      final sortedInteractions = [...interactions]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      setState(() {
        _interactions = sortedInteractions;
        _events = _buildEventsWithDividers(interactions, labelChanges);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Merges interactions and label changes into a chronological list,
  /// injecting [PeriodDividerTimelineEvent] markers at each period boundary.
  ///
  /// A "period" is the span of time during which one relationship label was active.
  /// Periods are delimited by label-change events.
  List<TimelineEvent> _buildEventsWithDividers(
    List<Interaction> interactions,
    List<LabelChange> labelChanges,
  ) {
    final sortedInteractions = [...interactions]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final sortedLabelChanges = [...labelChanges]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Merge and sort all non-divider events oldest-first.
    final allEvents = <TimelineEvent>[
      ...sortedInteractions.map(InteractionTimelineEvent.new),
      ...sortedLabelChanges.map(LabelChangeTimelineEvent.new),
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // No label changes → no period grouping needed.
    if (sortedLabelChanges.isEmpty) return allEvents;

    final result = <TimelineEvent>[];
    int lcIndex = 0;

    // Inject the initial period divider (before the first label change).
    final firstLcTime = sortedLabelChanges[0].createdAt;
    final initInteractions = sortedInteractions
        .where((i) => i.createdAt.isBefore(firstLcTime))
        .toList();
    result.add(PeriodDividerTimelineEvent(
      label: sortedLabelChanges[0].fromLabel,
      start: null, // "from the beginning"
      end: firstLcTime,
      interactionCount: initInteractions.length,
      averageScore: _avg(initInteractions),
    ));

    for (final event in allEvents) {
      if (event is LabelChangeTimelineEvent &&
          lcIndex < sortedLabelChanges.length &&
          event.change.id == sortedLabelChanges[lcIndex].id) {
        // Add the label-change event itself.
        result.add(event);
        final lc = sortedLabelChanges[lcIndex];
        lcIndex++;

        // Inject divider for the period that starts after this label change.
        final nextLcTime = lcIndex < sortedLabelChanges.length
            ? sortedLabelChanges[lcIndex].createdAt
            : null;
        final periodInteractions = sortedInteractions.where((i) {
          final afterStart = !i.createdAt.isBefore(lc.createdAt);
          final beforeEnd =
              nextLcTime == null || i.createdAt.isBefore(nextLcTime);
          return afterStart && beforeEnd;
        }).toList();
        result.add(PeriodDividerTimelineEvent(
          label: lc.toLabel,
          start: lc.createdAt,
          end: nextLcTime,
          interactionCount: periodInteractions.length,
          averageScore: _avg(periodInteractions),
        ));
      } else {
        result.add(event);
      }
    }

    return result;
  }

  static double _avg(List<Interaction> interactions) {
    if (interactions.isEmpty) return 0;
    final sum = interactions.fold<int>(0, (s, i) => s + i.score);
    return sum / interactions.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.friendName} — Timeline'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? const Center(
                  child: Text(
                    'No events yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _StatsHeader(interactions: _interactions),
                    ),
                    if (_interactions.length > 1)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                          child: ScoreSparkline(interactions: _interactions),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      sliver: SliverList.builder(
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          if (event is PeriodDividerTimelineEvent) {
                            return PeriodDividerTile(event: event);
                          }
                          // Break the connector line at period-divider boundaries.
                          final prev =
                              index > 0 ? _events[index - 1] : null;
                          final next = index < _events.length - 1
                              ? _events[index + 1]
                              : null;
                          return TimelineTile(
                            event: event,
                            isFirst: prev == null ||
                                prev is PeriodDividerTimelineEvent,
                            isLast: next == null ||
                                next is PeriodDividerTimelineEvent,
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats header
// ---------------------------------------------------------------------------

class _StatsHeader extends StatelessWidget {
  final List<Interaction> interactions; // sorted ascending

  const _StatsHeader({required this.interactions});

  @override
  Widget build(BuildContext context) {
    if (interactions.isEmpty) return const SizedBox.shrink();

    final total = interactions.length;
    final avg =
        interactions.fold<int>(0, (s, i) => s + i.score) / total;
    final positive = interactions.where((i) => i.score > 0).length;
    final positivePct = (positive / total * 100).round();
    final lastDate = interactions.last.createdAt;

    final avgColor = avg > 0
        ? const Color(0xFF2E7D32)
        : avg < 0
            ? const Color(0xFFC62828)
            : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StatBox(label: 'Total', value: '$total'),
              _StatBox(
                label: 'Avg Score',
                value:
                    avg >= 0 ? '+${avg.toStringAsFixed(1)}' : avg.toStringAsFixed(1),
                valueColor: avgColor,
              ),
              _StatBox(
                label: 'Positive',
                value: '$positivePct%',
                valueColor: positivePct >= 50
                    ? const Color(0xFF2E7D32)
                    : Colors.grey.shade600,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Last interaction: ${DateFormat('MMM d, yyyy').format(lastDate.toLocal())}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatBox({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Score sparkline
// ---------------------------------------------------------------------------

/// Compact line chart of score over time. No axes labels — purely visual.
/// Uses CustomPaint; no charting library needed.
class ScoreSparkline extends StatelessWidget {
  final List<Interaction> interactions; // sorted ascending by createdAt

  const ScoreSparkline({super.key, required this.interactions});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: CustomPaint(
        painter: _SparklinePainter(interactions),
        size: Size.infinite,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<Interaction> interactions;

  _SparklinePainter(this.interactions);

  static const double _minScore = -3;
  static const double _maxScore = 3;
  static const double _dotRadius = 5;
  static const double _padH = 8; // horizontal padding
  static const double _padV = 10; // vertical padding

  @override
  void paint(Canvas canvas, Size size) {
    if (interactions.isEmpty) return;

    final w = size.width;
    final h = size.height;

    // Zero baseline.
    final zeroY = _toY(0, h);
    final baselinePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    canvas.drawLine(Offset(_padH, zeroY), Offset(w - _padH, zeroY), baselinePaint);

    // Compute canvas points.
    final points = _toPoints(w, h);

    if (points.length > 1) {
      // Connecting polyline.
      final linePaint = Paint()
        ..color = Colors.grey.shade400
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Dots.
    for (var i = 0; i < points.length; i++) {
      _drawDot(canvas, points[i], interactions[i].score);
    }
  }

  List<Offset> _toPoints(double w, double h) {
    final firstMs =
        interactions.first.createdAt.millisecondsSinceEpoch.toDouble();
    final lastMs =
        interactions.last.createdAt.millisecondsSinceEpoch.toDouble();
    final timeRange = lastMs - firstMs;

    return interactions.map((i) {
      final x = timeRange == 0
          ? w / 2
          : _padH +
              (i.createdAt.millisecondsSinceEpoch - firstMs) /
                  timeRange *
                  (w - _padH * 2);
      return Offset(x, _toY(i.score.toDouble(), h));
    }).toList();
  }

  double _toY(double score, double height) {
    // score [-3, 3] → y [height - padV, padV]
    final t = (score - _minScore) / (_maxScore - _minScore); // 0..1
    return (height - _padV) - t * (height - _padV * 2);
  }

  void _drawDot(Canvas canvas, Offset center, int score) {
    final color = score > 0
        ? const Color(0xFF2E7D32)
        : score < 0
            ? const Color(0xFFC62828)
            : Colors.grey;
    canvas.drawCircle(center, _dotRadius, Paint()..color = color);
    canvas.drawCircle(
      center,
      _dotRadius,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.interactions != interactions;
}
