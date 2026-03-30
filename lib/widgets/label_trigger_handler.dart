// label_trigger_handler.dart
// Shared utility for handling label engine evaluation results.
// Used by AddInteractionScreen, EditInteractionScreen, and the delete flow
// in FriendDetailScreen. Shows the label suggestion dialog and applies
// any accepted label change.

import 'package:flutter/material.dart';
import '../models/friend.dart';
import '../models/label_change.dart';
import '../services/friend_service.dart';
import '../services/interaction_service.dart';
import '../services/label_engine.dart';
import '../utils/constants.dart';

/// Shows the label suggestion dialog for [evaluation] and, if the user accepts,
/// updates the friend's label and records a system-triggered label change.
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
      options = [RelationshipLabel.responsive, RelationshipLabel.obligatory];
      break;
    case LabelTrigger.windowPositiveUpgrade:
      message = 'The last ${evaluation.windowSize} interactions total '
          '+${evaluation.windowTotal} points. '
          '${friend.label.displayName} friends with sustained positive scores '
          'can be upgraded to Active.';
      options = [RelationshipLabel.active];
      break;
    case LabelTrigger.none:
      return;
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
    await friendService.updateLabel(friendId: friend.id, newLabel: chosen);
    await interactionService.saveLabelChange(
      friendId: friend.id,
      fromLabel: friend.label,
      toLabel: chosen,
      triggeredBy: ChangeTriggeredBy.system,
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
          Text(widget.message, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          if (widget.suggestedOptions.length > 1) ...[
            const Text('Move to:', style: TextStyle(fontWeight: FontWeight.w600)),
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
