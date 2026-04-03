// add_interaction_screen.dart
// Screen for recording a new interaction with a friend.
// Shows score picker and optional note. After saving, displays label change
// suggestion dialog if the label engine triggers one.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/friend.dart';
import '../models/interaction.dart';
import '../services/friend_service.dart';
import '../services/interaction_service.dart';
import '../utils/constants.dart';
import '../widgets/label_trigger_handler.dart';
import '../widgets/score_picker.dart';
import '../theme/crayon_theme.dart';
import '../theme/crayon_widgets.dart';

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
  DateTime _interactionDate = DateTime.now();
  List<Interaction> _recentInteractions = [];
  bool _historyLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final all = await _interactionService.getInteractionsForFriend(widget.friend.id);
    if (mounted) {
      setState(() {
        _recentInteractions = all.take(3).toList();
        _historyLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
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
        interactionDate: _interactionDate,
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
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _interactionDate,
                  firstDate: DateTime(now.year - 5),
                  lastDate: now,
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: CrayonColors.accentPurple,
                        onPrimary: CrayonColors.textPrimary,
                        surface: CrayonColors.background,
                        onSurface: CrayonColors.textPrimary,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _interactionDate = picked);
              },
              child: CrayonCard(
                seed: 55,
                fillColor: CrayonColors.surface,
                strokeColor: CrayonColors.strokeLight,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: CrayonColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'When? ${DateFormat('MMM d, yyyy').format(_interactionDate)}',
                        style: GoogleFonts.caveat(
                          fontSize: 18,
                          color: CrayonColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      _isToday(_interactionDate) ? 'Today' : '',
                      style: GoogleFonts.caveat(
                        fontSize: 15,
                        color: CrayonColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Why this score? (optional)',
                hintText: 'Write a note, or leave blank...',
              ),
            ),
            const SizedBox(height: 20),
            if (_historyLoaded && _recentInteractions.isEmpty)
              CrayonCard(
                seed: 77,
                fillColor: CrayonColors.surfaceAlt,
                strokeColor: CrayonColors.strokeLight,
                padding: const EdgeInsets.all(14),
                child: Text(
                  'This is your first interaction with ${widget.friend.name}!',
                  style: GoogleFonts.caveat(
                    fontSize: 18,
                    color: CrayonColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            if (_historyLoaded && _recentInteractions.isNotEmpty) ...[
              Text(
                'Recent',
                style: GoogleFonts.caveat(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: CrayonColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ..._recentInteractions.asMap().entries.map((e) {
                final i = e.value;
                final idx = e.key;
                final fill = scoreFillColor(i.score);
                final textCol = scoreTextColor(i.score);
                final label = i.score > 0 ? '+${i.score}' : '${i.score}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: CrayonCard(
                    seed: idx * 13 + 44,
                    fillColor: CrayonColors.surface,
                    strokeColor: CrayonColors.strokeLight,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        CrayonCircle(
                          fillColor: fill.withAlpha(80),
                          strokeColor: fill,
                          size: 34,
                          seed: i.score + 30,
                          child: Text(
                            label,
                            style: GoogleFonts.caveat(
                              color: textCol,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            scoreDescriptions[i.score] ?? '',
                            style: GoogleFonts.caveat(
                              fontSize: 16,
                              color: CrayonColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('MMM d').format(i.createdAt.toLocal()),
                          style: GoogleFonts.caveat(
                            fontSize: 14,
                            color: CrayonColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 16),
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

