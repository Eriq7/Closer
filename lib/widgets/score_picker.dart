// score_picker.dart
// Interactive widget for selecting a score from -3 to +3.
// Uses CrayonCircle for the score buttons and CrayonCard for the description box.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../theme/crayon_theme.dart';
import '../theme/crayon_widgets.dart';

class ScorePicker extends StatelessWidget {
  final int selectedScore;
  final ValueChanged<int> onChanged;

  const ScorePicker({
    super.key,
    required this.selectedScore,
    required this.onChanged,
  });

  Color _fillForScore(int score, bool selected) {
    final base = scoreFillColor(score);
    return selected ? base : base.withValues(alpha: 0.3);
  }

  Color _strokeForScore(int score) => scoreFillColor(score);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final score = i - 3;
            final isSelected = score == selectedScore;
            final label = score > 0 ? '+$score' : '$score';
            final seed = score + 100;

            return GestureDetector(
              onTap: () => onChanged(score),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: isSelected ? 1.0 : 0.65,
                child: CrayonCircle(
                  fillColor: _fillForScore(score, isSelected),
                  strokeColor: isSelected
                      ? _strokeForScore(score)
                      : _strokeForScore(score).withValues(alpha: 0.4),
                  size: isSelected ? 44 : 38,
                  seed: seed,
                  child: Text(
                    label,
                    style: GoogleFonts.caveat(
                      color: isSelected
                          ? scoreTextColor(score)
                          : CrayonColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: isSelected ? 17 : 15,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: CrayonCard(
            key: ValueKey(selectedScore),
            fillColor: scoreFillColor(selectedScore).withValues(alpha: 0.15),
            strokeColor: scoreFillColor(selectedScore).withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            cornerRadius: 10,
            seed: selectedScore + 200,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    scoreDescriptions[selectedScore] ?? '',
                    style: GoogleFonts.caveat(
                      color: scoreTextColor(selectedScore),
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
