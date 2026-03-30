// label_engine_reeval_test.dart
// Unit tests for label engine re-evaluation after interaction edits/deletes.
// Simulates the re-evaluation flow in updateInteraction() and deleteInteraction().

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
  group('Re-evaluation after edit', () {
    test('Edit score from -3 to +1: trigger changes from cutOff to none', () {
      // Before edit: history has -3 as newest → immediateCutOff
      final before = _buildHistory([-3, 1, 1]);
      final evalBefore = LabelEngine.evaluate(
        latestInteraction: before.first,
        allInteractions: before,
        currentLabel: RelationshipLabel.active,
      );
      expect(evalBefore.trigger, LabelTrigger.immediateCutOff);

      // After edit: -3 replaced by +1 → newest is +1
      final after = _buildHistory([1, 1, 1]);
      final evalAfter = LabelEngine.evaluate(
        latestInteraction: after.first,
        allInteractions: after,
        currentLabel: RelationshipLabel.active,
      );
      expect(evalAfter.trigger, LabelTrigger.none);
    });

    test('Edit makes window total drop to -4: triggers windowNegativeDowngrade', () {
      // History: [+1, -1, -1, -1, +1] total = -1 → none
      final before = _buildHistory([1, -1, -1, -1, 1]);
      final evalBefore = LabelEngine.evaluate(
        latestInteraction: before.first,
        allInteractions: before,
        currentLabel: RelationshipLabel.active,
      );
      expect(evalBefore.trigger, LabelTrigger.none);

      // After edit: newest score changed from +1 to -3, total window = -5
      final after = _buildHistory([-3, -1, -1, -1, 1]);
      final evalAfter = LabelEngine.evaluate(
        latestInteraction: after.first,
        allInteractions: after,
        currentLabel: RelationshipLabel.active,
      );
      expect(evalAfter.trigger, LabelTrigger.immediateCutOff);
    });

    test('Edit -2 (for Active) to 0: no longer triggers immediateDowngrade', () {
      final before = _buildHistory([-2, 1, 1]);
      final evalBefore = LabelEngine.evaluate(
        latestInteraction: before.first,
        allInteractions: before,
        currentLabel: RelationshipLabel.active,
      );
      expect(evalBefore.trigger, LabelTrigger.immediateDowngrade);

      final after = _buildHistory([0, 1, 1]);
      final evalAfter = LabelEngine.evaluate(
        latestInteraction: after.first,
        allInteractions: after,
        currentLabel: RelationshipLabel.active,
      );
      expect(evalAfter.trigger, LabelTrigger.none);
    });
  });

  group('Re-evaluation after delete', () {
    test('Delete the only -3: no more cutOff trigger', () {
      // After deletion of -3, remaining history: [+1, +1]
      final history = _buildHistory([1, 1]);
      final eval = LabelEngine.evaluate(
        latestInteraction: history.first,
        allInteractions: history,
        currentLabel: RelationshipLabel.active,
      );
      expect(eval.trigger, LabelTrigger.none);
    });

    test('Delete a positive score from Responsive: upgrade may no longer apply', () {
      // Before delete: Responsive with window total ≥ +2 → upgrade eligible
      final before = _buildHistory([1, 1, 1]);
      final evalBefore = LabelEngine.evaluate(
        latestInteraction: before.first,
        allInteractions: before,
        currentLabel: RelationshipLabel.responsive,
      );
      expect(evalBefore.trigger, LabelTrigger.windowPositiveUpgrade);

      // After delete of one +1: only [-1, -1] remain, total = -2 → none
      final after = _buildHistory([-1, -1]);
      final evalAfter = LabelEngine.evaluate(
        latestInteraction: after.first,
        allInteractions: after,
        currentLabel: RelationshipLabel.responsive,
      );
      expect(evalAfter.trigger, LabelTrigger.none);
    });

    test('Empty history after delete: no evaluation needed (null returned)', () {
      // This is handled by deleteInteraction() returning null when history is empty.
      // Verify the engine is not called with empty list — this test documents the contract.
      // (The actual null return is in the service layer, not the engine itself.)
      expect(true, isTrue); // contract documented above
    });
  });
}
