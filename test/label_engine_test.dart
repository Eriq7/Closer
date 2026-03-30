// label_engine_test.dart
// Unit tests for the core label switching logic in LabelEngine.
// No Supabase connection needed — pure Dart logic tests.

import 'package:flutter_test/flutter_test.dart';
import 'package:closer/services/label_engine.dart';
import 'package:closer/models/interaction.dart';
import 'package:closer/utils/constants.dart';

Interaction _fakeInteraction({
  required int score,
  required DateTime createdAt,
}) {
  return Interaction(
    id: 'test-id',
    friendId: 'friend-id',
    userId: 'user-id',
    score: score,
    createdAt: createdAt,
  );
}

List<Interaction> _buildHistory(List<int> scores, {int daysBetween = 7}) {
  final now = DateTime.now();
  return List.generate(scores.length, (i) {
    return _fakeInteraction(
      score: scores[i],
      createdAt: now.subtract(Duration(days: i * daysBetween)),
    );
  });
}

void main() {
  group('Single-event rules', () {
    test('score -3 triggers immediateCutOff regardless of label', () {
      for (final label in RelationshipLabel.values) {
        final latest = _fakeInteraction(score: -3, createdAt: DateTime.now());
        final result = LabelEngine.evaluate(
          latestInteraction: latest,
          allInteractions: [latest],
          currentLabel: label,
          contactFrequency: ContactFrequency.rarely,
        );
        expect(result.trigger, LabelTrigger.immediateCutOff,
            reason: 'label=$label');
      }
    });

    test('score -2 on Active triggers immediateDowngrade', () {
      final latest = _fakeInteraction(score: -2, createdAt: DateTime.now());
      final result = LabelEngine.evaluate(
        latestInteraction: latest,
        allInteractions: [latest],
        currentLabel: RelationshipLabel.active,
        contactFrequency: ContactFrequency.rarely,
      );
      expect(result.trigger, LabelTrigger.immediateDowngrade);
    });

    test('score -2 on Responsive triggers immediateDowngrade', () {
      final latest = _fakeInteraction(score: -2, createdAt: DateTime.now());
      final result = LabelEngine.evaluate(
        latestInteraction: latest,
        allInteractions: [latest],
        currentLabel: RelationshipLabel.responsive,
        contactFrequency: ContactFrequency.rarely,
      );
      expect(result.trigger, LabelTrigger.immediateDowngrade);
    });

    test('score -2 on Obligatory does NOT trigger single-event downgrade', () {
      final latest = _fakeInteraction(score: -2, createdAt: DateTime.now());
      final result = LabelEngine.evaluate(
        latestInteraction: latest,
        allInteractions: [latest],
        currentLabel: RelationshipLabel.obligatory,
        contactFrequency: ContactFrequency.rarely,
      );
      expect(result.trigger, isNot(LabelTrigger.immediateDowngrade));
    });

    test('score -1 does not trigger any single-event rule', () {
      final latest = _fakeInteraction(score: -1, createdAt: DateTime.now());
      final result = LabelEngine.evaluate(
        latestInteraction: latest,
        allInteractions: [latest],
        currentLabel: RelationshipLabel.active,
        contactFrequency: ContactFrequency.rarely,
      );
      expect(result.trigger, LabelTrigger.none);
    });
  });

  group('Window size determination', () {
    test('ContactFrequency.often → windowSize 5', () {
      final history = _buildHistory([1, 1, 1, 1, 1]);
      final latest = history.first;
      final result = LabelEngine.evaluate(
        latestInteraction: latest,
        allInteractions: history,
        currentLabel: RelationshipLabel.active,
        contactFrequency: ContactFrequency.often,
      );
      expect(result.windowSize, 5);
    });

    test('ContactFrequency.rarely → windowSize 3', () {
      final history = _buildHistory([1, 1, 1]);
      final latest = history.first;
      final result = LabelEngine.evaluate(
        latestInteraction: latest,
        allInteractions: history,
        currentLabel: RelationshipLabel.active,
        contactFrequency: ContactFrequency.rarely,
      );
      expect(result.windowSize, 3);
    });

    test('fewer interactions than window size → trigger is none', () {
      // rarely uses windowSize 3; only 2 interactions → too few to evaluate
      final history = _buildHistory([1, 1]);
      final latest = history.first;
      final result = LabelEngine.evaluate(
        latestInteraction: latest,
        allInteractions: history,
        currentLabel: RelationshipLabel.active,
        contactFrequency: ContactFrequency.rarely,
      );
      expect(result.trigger, LabelTrigger.none);
    });
  });

  group('Window total rules', () {
    test('Responsive with window total +2 → windowPositiveUpgrade', () {
      // often → 5 score window
      final history = _buildHistory([2, 1, 1, -1, -1], daysBetween: 7);
      // total of first 5: 2+1+1-1-1 = 2
      final latest = history.first;
      final result = LabelEngine.evaluate(
        latestInteraction: latest,
        allInteractions: history,
        currentLabel: RelationshipLabel.responsive,
        contactFrequency: ContactFrequency.often,
      );
      expect(result.trigger, LabelTrigger.windowPositiveUpgrade);
    });

    test('window total -4 → windowNegativeDowngrade', () {
      // rarely → 3 score window
      // Latest score is -1 (not -2) to avoid triggering the single-event rule.
      // Window of 3: -1 + -2 + -1 = -4
      final history = _buildHistory([-1, -2, -1, 1, 1], daysBetween: 30);
      final latest = history.first;
      final result = LabelEngine.evaluate(
        latestInteraction: latest,
        allInteractions: history,
        currentLabel: RelationshipLabel.active,
        contactFrequency: ContactFrequency.rarely,
      );
      expect(result.trigger, LabelTrigger.windowNegativeDowngrade);
    });

    test('window total 0 → windowNoChange (window complete, no label change)', () {
      // rarely → 3 score window; total = 0+0+0 = 0, no trigger but window complete
      final history = _buildHistory([0, 0, 0], daysBetween: 30);
      final latest = history.first;
      final result = LabelEngine.evaluate(
        latestInteraction: latest,
        allInteractions: history,
        currentLabel: RelationshipLabel.active,
        contactFrequency: ContactFrequency.rarely,
      );
      expect(result.trigger, LabelTrigger.windowNoChange);
    });
  });

  group('Downgrade results', () {
    test('Active → downgrade → Responsive', () {
      expect(
        LabelEngine.applyDowngrade(RelationshipLabel.active),
        RelationshipLabel.responsive,
      );
    });

    test('Responsive → downgrade → Cut-off', () {
      expect(
        LabelEngine.applyDowngrade(RelationshipLabel.responsive),
        RelationshipLabel.cutOff,
      );
    });

    test('Obligatory → downgrade → Cut-off', () {
      expect(
        LabelEngine.applyDowngrade(RelationshipLabel.obligatory),
        RelationshipLabel.cutOff,
      );
    });
  });
}
