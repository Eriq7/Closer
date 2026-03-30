// label_engine.dart
// Core business logic: evaluates a friend's interaction history and determines
// whether a label change should be triggered.
//
// Rules:
// - Single-event: score -3 → Cut-off; score -2 → downgrade one level
// - Window: avg interval ≤21 days → use last 5 scores; else last 3
// - Window total ≤-4 → prompt downgrade to Responsive or Obligatory
// - Window total ≥+2 (Responsive) → eligible to upgrade to Active

import '../models/interaction.dart';
import '../utils/constants.dart';

enum LabelTrigger {
  none,
  immediateCutOff,        // Single -3
  immediateDowngrade,     // Single -2
  windowNegativeDowngrade, // Window total ≤ -4
  windowPositiveUpgrade,  // Responsive window total ≥ +2
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
  /// Evaluates the latest interaction against the full history and returns
  /// what action (if any) should be triggered.
  static LabelEvaluation evaluate({
    required Interaction latestInteraction,
    required List<Interaction> allInteractions, // sorted newest-first
    required RelationshipLabel currentLabel,
  }) {
    // Single-event rules first — highest priority.
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
    final windowSize = _determineWindowSize(allInteractions);
    final window = allInteractions.take(windowSize).toList();
    final total = window.fold<int>(0, (sum, i) => sum + i.score);

    if (total <= windowNegativeTrigger) {
      return LabelEvaluation(
        trigger: LabelTrigger.windowNegativeDowngrade,
        windowTotal: total,
        windowSize: windowSize,
      );
    }

    if (currentLabel == RelationshipLabel.responsive &&
        total >= windowPositiveUpgrade) {
      return LabelEvaluation(
        trigger: LabelTrigger.windowPositiveUpgrade,
        windowTotal: total,
        windowSize: windowSize,
      );
    }

    return LabelEvaluation(
      trigger: LabelTrigger.none,
      windowTotal: total,
      windowSize: windowSize,
    );
  }

  /// Determines window size (5 or 3) based on average interval between interactions.
  static int _determineWindowSize(List<Interaction> interactions) {
    if (interactions.length < 2) return lowFrequencyWindowSize;

    // Use up to the 6 most recent to calculate average interval.
    final sample = interactions.take(6).toList();
    double totalDays = 0;
    for (int i = 0; i < sample.length - 1; i++) {
      totalDays += sample[i]
          .createdAt
          .difference(sample[i + 1].createdAt)
          .inDays
          .abs()
          .toDouble();
    }
    final avgDays = totalDays / (sample.length - 1);

    return avgDays <= highFrequencyThresholdDays
        ? highFrequencyWindowSize
        : lowFrequencyWindowSize;
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
