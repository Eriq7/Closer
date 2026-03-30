// edit_interaction_screen.dart
// Screen for editing an existing interaction's score and note.
// Pre-fills the current score and note. After saving, re-evaluates the label
// engine and shows a suggestion dialog if a trigger fires.

import 'package:flutter/material.dart';
import '../models/friend.dart';
import '../models/interaction.dart';
import '../services/friend_service.dart';
import '../services/interaction_service.dart';
import '../services/label_engine.dart';
import '../widgets/label_trigger_handler.dart';
import '../widgets/score_picker.dart';

class EditInteractionScreen extends StatefulWidget {
  final Friend friend;
  final Interaction interaction;

  const EditInteractionScreen({
    super.key,
    required this.friend,
    required this.interaction,
  });

  @override
  State<EditInteractionScreen> createState() => _EditInteractionScreenState();
}

class _EditInteractionScreenState extends State<EditInteractionScreen> {
  late int _score;
  late final TextEditingController _noteController;
  final _interactionService = InteractionService();
  final _friendService = FriendService();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _score = widget.interaction.score;
    _noteController =
        TextEditingController(text: widget.interaction.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final result = await _interactionService.updateInteraction(
        interactionId: widget.interaction.id,
        friendId: widget.friend.id,
        score: _score,
        note: _noteController.text,
        currentLabel: widget.friend.label,
        contactFrequency: widget.friend.contactFrequency,
        windowAnchorAt: widget.friend.windowAnchorAt,
      );

      if (!mounted) return;

      final evaluation = result.evaluation;

      if (evaluation.trigger != LabelTrigger.none) {
        await handleLabelTrigger(
          context: context,
          evaluation: evaluation,
          friend: widget.friend,
          friendService: _friendService,
          interactionService: _interactionService,
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Interaction — ${widget.friend.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'How did this interaction feel?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ScorePicker(
              selectedScore: _score,
              onChanged: (s) => setState(() => _score = s),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Why this score? (optional)',
                hintText: 'Write a note, or leave blank...',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
