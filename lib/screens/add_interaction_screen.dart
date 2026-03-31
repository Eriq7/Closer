// add_interaction_screen.dart
// Screen for recording a new interaction with a friend.
// Shows score picker and optional note. After saving, displays label change
// suggestion dialog if the label engine triggers one.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/friend.dart';
import '../services/friend_service.dart';
import '../services/interaction_service.dart';
import '../widgets/label_trigger_handler.dart';
import '../widgets/score_picker.dart';
import '../theme/crayon_theme.dart';

class AddInteractionScreen extends StatefulWidget {
  final Friend friend;

  const AddInteractionScreen({super.key, required this.friend});

  @override
  State<AddInteractionScreen> createState() => _AddInteractionScreenState();
}

class _AddInteractionScreenState extends State<AddInteractionScreen> {
  int _score = 0;
  final _noteController = TextEditingController();
  final _interactionService = InteractionService();
  final _friendService = FriendService();
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final result = await _interactionService.addInteraction(
        friendId: widget.friend.id,
        score: _score,
        note: _noteController.text,
        currentLabel: widget.friend.label,
        contactFrequency: widget.friend.contactFrequency,
        windowAnchorAt: widget.friend.windowAnchorAt,
      );

      if (!mounted) return;

      final evaluation = result.evaluation;

      await handleLabelTrigger(
        context: context,
        evaluation: evaluation,
        friend: widget.friend,
        friendService: _friendService,
        interactionService: _interactionService,
      );

      if (mounted) context.pop(true);
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
        title: Text('Log Interaction — ${widget.friend.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How did this interaction feel?',
              style: GoogleFonts.caveat(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: CrayonColors.textPrimary,
              ),
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

