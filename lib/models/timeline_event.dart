// timeline_event.dart
// Union type wrapping either an Interaction or a LabelChange for
// use in the per-friend timeline view. Sorted by createdAt ascending.

import 'interaction.dart';
import 'label_change.dart';

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
