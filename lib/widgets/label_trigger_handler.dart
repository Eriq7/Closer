// label_trigger_handler.dart
// Shared utility for handling label engine evaluation results.
// Used by AddInteractionScreen, EditInteractionScreen, and the delete flow
// in FriendDetailScreen. Shows the label suggestion dialog and applies
// any accepted label change.
//
// Key rules:
// - Options are filtered to exclude the friend's current label (no no-op changes).
// - If no valid options remain (same-label case), shows a simple informational
//   dialog and resets the window anchor — does NOT write to label_changes.
// - clearPendingEvaluation is called internally; callers do NOT need to call it.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/friend.dart';
import '../models/label_change.dart';
import '../services/friend_service.dart';
import '../services/interaction_service.dart';
import '../services/label_engine.dart';
import '../utils/constants.dart';
import '../theme/crayon_theme.dart';

/// Shows the label suggestion dialog for [evaluation] and, if the user accepts,
/// updates the friend's label and records a system-triggered label change.
///
/// Handles window anchor reset internally — caller does NOT need to call
/// clearPendingEvaluation after this function returns.
///
/// [friend] is used for its current label (for applyDowngrade) and id.
/// Does NOT call setState or pop — caller is responsible for refreshing UI.
Future<void> handleLabelTrigger({
  required BuildContext context,
  required LabelEvaluation evaluation,
  required Friend friend,
  required FriendService friendService,
  required InteractionService interactionService,
}) async {
  if (evaluation.trigger == LabelTrigger.none) return;

  // Window completed with no label change warranted — show informational dialog only.
  if (evaluation.trigger == LabelTrigger.windowNoChange) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Relationship Check'),
        content: Text(
          'Based on the last ${evaluation.windowSize} interactions, '
          '${friend.name} is still ${friend.label.displayName}.',
          style: GoogleFonts.caveat(fontSize: 16, color: CrayonColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    await friendService.clearPendingEvaluation(
      friend.id,
      anchorTimestamp: evaluation.anchorTimestamp,
    );
    return;
  }

  String message;
  List<RelationshipLabel> options;

  switch (evaluation.trigger) {
    case LabelTrigger.immediateCutOff:
      message = 'A score of -3 is a line-crossing event. '
          'The system recommends moving this person to Cut-off.';
      options = [RelationshipLabel.cutOff];
      break;
    case LabelTrigger.immediateDowngrade:
      final next = LabelEngine.applyDowngrade(friend.label);
      message = 'A score of -2 triggers a downgrade. '
          'The system recommends: ${friend.label.displayName} → ${next.displayName}.';
      options = [next];
      break;
    case LabelTrigger.windowNegativeDowngrade:
      message = 'The last ${evaluation.windowSize} interactions total '
          '${evaluation.windowTotal} points. '
          'This pattern suggests re-evaluating this relationship.';
      // Only offer labels that are actually different from the current one.
      options = [RelationshipLabel.responsive, RelationshipLabel.obligatory]
          .where((l) => l != friend.label)
          .toList();
      break;
    case LabelTrigger.windowPositiveUpgrade:
      if (friend.label == RelationshipLabel.obligatory) {
        message = 'The last ${evaluation.windowSize} interactions total '
            '+${evaluation.windowTotal} points. '
            'This relationship seems to be improving — would you like to re-categorize?';
        options = [RelationshipLabel.responsive, RelationshipLabel.active];
      } else {
        message = 'The last ${evaluation.windowSize} interactions total '
            '+${evaluation.windowTotal} points. '
            '${friend.label.displayName} friends with sustained positive scores '
            'can be upgraded to Active.';
        options = [RelationshipLabel.active]
            .where((l) => l != friend.label)
            .toList();
      }
      break;
    case LabelTrigger.none:
      return;
    case LabelTrigger.windowNoChange:
      return; // handled above before the switch
  }

  if (!context.mounted) return;

  final chosen = await showDialog<RelationshipLabel>(
    context: context,
    builder: (_) => _LabelSuggestionDialog(
      friendName: friend.name,
      message: message,
      currentLabel: friend.label,
      suggestedOptions: options,
      trigger: evaluation.trigger,
    ),
  );

  if (chosen != null && context.mounted) {
    // Label changed: updateLabel clears pending_evaluation and sets anchor.
    await friendService.updateLabel(
      friendId: friend.id,
      newLabel: chosen,
      anchorTimestamp: evaluation.anchorTimestamp,
    );
    await interactionService.saveLabelChange(
      friendId: friend.id,
      fromLabel: friend.label,
      toLabel: chosen,
      triggeredBy: ChangeTriggeredBy.system,
    );
  } else {
    // User kept current label — still reset the window anchor so the next
    // evaluation window starts fresh from the triggering interaction.
    await friendService.clearPendingEvaluation(
      friend.id,
      anchorTimestamp: evaluation.anchorTimestamp,
    );
  }
}

class _LabelSuggestionDialog extends StatefulWidget {
  final String friendName;
  final String message;
  final RelationshipLabel currentLabel;
  final List<RelationshipLabel> suggestedOptions;
  final LabelTrigger trigger;

  const _LabelSuggestionDialog({
    required this.friendName,
    required this.message,
    required this.currentLabel,
    required this.suggestedOptions,
    required this.trigger,
  });

  @override
  State<_LabelSuggestionDialog> createState() => _LabelSuggestionDialogState();
}

class _LabelSuggestionDialogState extends State<_LabelSuggestionDialog> {
  late RelationshipLabel _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.suggestedOptions.first;
  }

  @override
  Widget build(BuildContext context) {
    final isUpgrade = widget.trigger == LabelTrigger.windowPositiveUpgrade;

    return AlertDialog(
      title: Text(isUpgrade ? 'Upgrade Suggested' : 'Relationship Check'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message, style: GoogleFonts.caveat(fontSize: 16, color: CrayonColors.textPrimary)),
          const SizedBox(height: 16),
          if (widget.suggestedOptions.length > 1) ...[
            Text('Move to:', style: GoogleFonts.caveat(fontWeight: FontWeight.w700, fontSize: 16, color: CrayonColors.textPrimary)),
            const SizedBox(height: 8),
            ...widget.suggestedOptions.map(
              (label) => RadioListTile<RelationshipLabel>(
                value: label,
                groupValue: _selected,
                onChanged: (v) => setState(() => _selected = v!),
                title: Text(label.displayName),
                subtitle: Text(label.description,
                    style: const TextStyle(fontSize: 12)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Keep current label'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(isUpgrade ? 'Upgrade' : 'Change Label'),
        ),
      ],
    );
  }
}
