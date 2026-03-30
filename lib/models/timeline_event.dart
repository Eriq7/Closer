// timeline_event.dart
// Union type wrapping an Interaction, a LabelChange, or a period divider
// for use in the per-friend timeline view. Sorted by createdAt ascending.
// PeriodDividerTimelineEvent is synthetic (computed client-side, not from DB).

import 'interaction.dart';
import 'label_change.dart';
import '../utils/constants.dart';

sealed class TimelineEvent {
  DateTime get createdAt;
}

class InteractionTimelineEvent extends TimelineEvent {
  final Interaction interaction;
  InteractionTimelineEvent(this.interaction);

  @override
  DateTime get createdAt => interaction.createdAt;
}

class LabelChangeTimelineEvent extends TimelineEvent {
  final LabelChange change;
  LabelChangeTimelineEvent(this.change);

  @override
  DateTime get createdAt => change.createdAt;
}

/// Synthetic chapter divider injected between label-change periods.
/// Not fetched from DB — computed in FriendTimelineScreen._buildEventsWithDividers().
/// [createdAt] equals [start] and is used only for sort ordering; it is not displayed.
class PeriodDividerTimelineEvent extends TimelineEvent {
  final RelationshipLabel label;
  final DateTime? start;       // null = from the very beginning
  final DateTime? end;         // null = ongoing (current period)
  final int interactionCount;
  final double averageScore;

  PeriodDividerTimelineEvent({
    required this.label,
    required this.start,
    required this.end,
    required this.interactionCount,
    required this.averageScore,
  });

  @override
  DateTime get createdAt =>
      start ?? DateTime.fromMillisecondsSinceEpoch(0);
}
