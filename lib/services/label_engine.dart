// label_engine.dart
// Core business logic: evaluates a friend's interaction history and determines
// whether a label change should be triggered.
//
// Rules:
// - Single-event: score -3 → Cut-off; score -2 → downgrade one level (immediate)
// - Window size: often → 5, rarely → 3
// - Minimum interactions: must have at least window-size interactions to trigger window rules
// - Window total < 0 (label ≠ cut_off) → prompt downgrade
// - Window total > 0 (label == responsive) → eligible to upgrade to Active

import '../models/interaction.dart';
import '../utils/constants.dart';

enum LabelTrigger {
  none,
  immediateCutOff,         // Single -3
  immediateDowngrade,      // Single -2
  windowNegativeDowngrade, // Window total < 0
  windowPositiveUpgrade,   // Responsive window total > 0
}

class LabelEvaluation {
  final LabelTrigger trigger;
  final int windowTotal;
  final int windowSize;

  const LabelEvaluation({
    required this.trigger,
    required this.windowTotal,
    required this.windowSize,
  });
}

class LabelEngine {
  /// Evaluates the latest interaction against the full history.
  /// [allInteractions] must be sorted newest-first.
  /// [contactFrequency] determines the window size (often=5, rarely=3).
  static LabelEvaluation evaluate({
    required Interaction latestInteraction,
    required List<Interaction> allInteractions,
    required RelationshipLabel currentLabel,
    required ContactFrequency contactFrequency,
  }) {
    // Single-event rules — highest priority, no minimum interaction count.
    if (latestInteraction.score == -3) {
      return const LabelEvaluation(
        trigger: LabelTrigger.immediateCutOff,
        windowTotal: -3,
        windowSize: 1,
      );
    }

    if (latestInteraction.score == -2) {
      if (currentLabel == RelationshipLabel.active ||
          currentLabel == RelationshipLabel.responsive) {
        return const LabelEvaluation(
          trigger: LabelTrigger.immediateDowngrade,
          windowTotal: -2,
          windowSize: 1,
        );
      }
    }

    // Window-based rules.
    final windowSize = contactFrequency == ContactFrequency.often
        ? highFrequencyWindowSize
        : lowFrequencyWindowSize;

    // Not enough interactions yet — do not evaluate.
    if (allInteractions.length < windowSize) {
      return LabelEvaluation(
        trigger: LabelTrigger.none,
        windowTotal: allInteractions.fold(0, (s, i) => s + i.score),
        windowSize: windowSize,
      );
    }

    final window = allInteractions.take(windowSize).toList();
    final total = window.fold<int>(0, (sum, i) => sum + i.score);

    if (currentLabel != RelationshipLabel.cutOff) {
      if (total < 0) {
        return LabelEvaluation(
          trigger: LabelTrigger.windowNegativeDowngrade,
          windowTotal: total,
          windowSize: windowSize,
        );
      }

      if (currentLabel == RelationshipLabel.responsive && total > 0) {
        return LabelEvaluation(
          trigger: LabelTrigger.windowPositiveUpgrade,
          windowTotal: total,
          windowSize: windowSize,
        );
      }
    }

    return LabelEvaluation(
      trigger: LabelTrigger.none,
      windowTotal: total,
      windowSize: windowSize,
    );
  }

  /// Returns the resulting label after a downgrade.
  static RelationshipLabel applyDowngrade(RelationshipLabel current) {
    switch (current) {
      case RelationshipLabel.active:
        return RelationshipLabel.responsive;
      case RelationshipLabel.responsive:
        return RelationshipLabel.cutOff;
      case RelationshipLabel.obligatory:
        return RelationshipLabel.cutOff;
      case RelationshipLabel.cutOff:
        return RelationshipLabel.cutOff;
    }
  }
}
