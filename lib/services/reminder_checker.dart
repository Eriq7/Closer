// reminder_checker.dart
// Pure business logic for checking which friends need a reminder.
// No Flutter or Supabase dependency — fully unit-testable.
//
// Rules:
// - Active friend with no interaction for > activeReminderDays (21) → remind
// - Obligatory friend with no interaction for > obligatoryReEvalDays (60) → re-evaluate prompt

import '../models/friend.dart';
import '../utils/constants.dart';

enum ReminderType { activeNoContact, obligatoryReEval }

class ReminderResult {
  final Friend friend;
  final ReminderType type;
  final int daysSinceLastInteraction;

  const ReminderResult({
    required this.friend,
    required this.type,
    required this.daysSinceLastInteraction,
  });

  String get title {
    switch (type) {
      case ReminderType.activeNoContact:
        return 'Stay in touch with ${friend.name}';
      case ReminderType.obligatoryReEval:
        return 'Time to re-evaluate: ${friend.name}';
    }
  }

  String get body {
    switch (type) {
      case ReminderType.activeNoContact:
        return "It's been $daysSinceLastInteraction days since you last interacted.";
      case ReminderType.obligatoryReEval:
        return 'You haven\'t interacted in $daysSinceLastInteraction days. Is this relationship still worth maintaining?';
    }
  }
}

class ReminderChecker {
  /// Returns the list of reminders that should be shown.
  ///
  /// [friends] — full friend list.
  /// [lastInteractionDates] — map of friend id → most recent interaction date.
  ///   If a friend has no interactions, they are omitted from the map.
  /// [now] — current datetime (injectable for testing).
  static List<ReminderResult> check({
    required List<Friend> friends,
    required Map<String, DateTime> lastInteractionDates,
    required DateTime now,
  }) {
    final results = <ReminderResult>[];

    for (final friend in friends) {
      final lastDate = lastInteractionDates[friend.id];
      if (lastDate == null) continue; // no interactions recorded, skip

      final days = now.difference(lastDate).inDays;

      if (friend.label == RelationshipLabel.active &&
          days > activeReminderDays) {
        results.add(ReminderResult(
          friend: friend,
          type: ReminderType.activeNoContact,
          daysSinceLastInteraction: days,
        ));
      } else if (friend.label == RelationshipLabel.obligatory &&
          days > obligatoryReEvalDays) {
        results.add(ReminderResult(
          friend: friend,
          type: ReminderType.obligatoryReEval,
          daysSinceLastInteraction: days,
        ));
      }
    }

    return results;
  }
}
