// reminder_checker_test.dart
// Unit tests for ReminderChecker business logic.
// No Flutter or Supabase dependencies needed.

import 'package:flutter_test/flutter_test.dart';
import 'package:closer/models/friend.dart';
import 'package:closer/services/reminder_checker.dart';
import 'package:closer/utils/constants.dart';

Friend _fakeFriend(String id, RelationshipLabel label) {
  return Friend(
    id: id,
    userId: 'user-1',
    name: 'Test $id',
    label: label,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  final now = DateTime(2026, 3, 29);

  group('Active friend reminders', () {
    test('20 days since last interaction → no reminder', () {
      final friend = _fakeFriend('a1', RelationshipLabel.active);
      final results = ReminderChecker.check(
        friends: [friend],
        lastInteractionDates: {'a1': now.subtract(const Duration(days: 20))},
        now: now,
      );
      expect(results, isEmpty);
    });

    test('22 days since last interaction → reminder', () {
      final friend = _fakeFriend('a2', RelationshipLabel.active);
      final results = ReminderChecker.check(
        friends: [friend],
        lastInteractionDates: {'a2': now.subtract(const Duration(days: 22))},
        now: now,
      );
      expect(results.length, 1);
      expect(results.first.type, ReminderType.activeNoContact);
    });

    test('Exactly 21 days → no reminder (must be > 21)', () {
      final friend = _fakeFriend('a3', RelationshipLabel.active);
      final results = ReminderChecker.check(
        friends: [friend],
        lastInteractionDates: {'a3': now.subtract(const Duration(days: 21))},
        now: now,
      );
      expect(results, isEmpty);
    });
  });

  group('Obligatory friend reminders', () {
    test('59 days since last interaction → no reminder', () {
      final friend = _fakeFriend('o1', RelationshipLabel.obligatory);
      final results = ReminderChecker.check(
        friends: [friend],
        lastInteractionDates: {'o1': now.subtract(const Duration(days: 59))},
        now: now,
      );
      expect(results, isEmpty);
    });

    test('61 days since last interaction → re-eval reminder', () {
      final friend = _fakeFriend('o2', RelationshipLabel.obligatory);
      final results = ReminderChecker.check(
        friends: [friend],
        lastInteractionDates: {'o2': now.subtract(const Duration(days: 61))},
        now: now,
      );
      expect(results.length, 1);
      expect(results.first.type, ReminderType.obligatoryReEval);
    });
  });

  group('Non-remindable labels', () {
    test('Responsive friend with 30 days → no reminder', () {
      final friend = _fakeFriend('r1', RelationshipLabel.responsive);
      final results = ReminderChecker.check(
        friends: [friend],
        lastInteractionDates: {'r1': now.subtract(const Duration(days: 30))},
        now: now,
      );
      expect(results, isEmpty);
    });

    test('Cut-off friend with 100 days → no reminder', () {
      final friend = _fakeFriend('c1', RelationshipLabel.cutOff);
      final results = ReminderChecker.check(
        friends: [friend],
        lastInteractionDates: {'c1': now.subtract(const Duration(days: 100))},
        now: now,
      );
      expect(results, isEmpty);
    });
  });

  group('Edge cases', () {
    test('Friend with no interactions → no reminder', () {
      final friend = _fakeFriend('a4', RelationshipLabel.active);
      final results = ReminderChecker.check(
        friends: [friend],
        lastInteractionDates: {}, // no entry for a4
        now: now,
      );
      expect(results, isEmpty);
    });

    test('Multiple friends → correct subset gets reminders', () {
      final active = _fakeFriend('a5', RelationshipLabel.active);
      final obligatory = _fakeFriend('o3', RelationshipLabel.obligatory);
      final responsive = _fakeFriend('r2', RelationshipLabel.responsive);

      final results = ReminderChecker.check(
        friends: [active, obligatory, responsive],
        lastInteractionDates: {
          'a5': now.subtract(const Duration(days: 25)), // should remind
          'o3': now.subtract(const Duration(days: 30)), // 30 days, under 60 → no
          'r2': now.subtract(const Duration(days: 40)), // responsive → no
        },
        now: now,
      );
      expect(results.length, 1);
      expect(results.first.friend.id, 'a5');
    });
  });
}
