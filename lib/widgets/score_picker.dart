// score_picker.dart
// Interactive widget for selecting a score from -3 to +3.
// Shows the score description inline as the user changes selection.

import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ScorePicker extends StatelessWidget {
  final int selectedScore;
  final ValueChanged<int> onChanged;

  const ScorePicker({
    super.key,
    required this.selectedScore,
    required this.onChanged,
  });

  Color _colorForScore(int score) {
    if (score >= 2) return const Color(0xFF2E7D32);
    if (score == 1) return const Color(0xFF558B2F);
    if (score == 0) return Colors.grey;
    if (score == -1) return const Color(0xFFE65100);
    if (score == -2) return const Color(0xFFC62828);
    return const Color(0xFF880E4F);
  }

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
            final color = _colorForScore(score);
            return GestureDetector(
              onTap: () => onChanged(score),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? color : color.withOpacity(0.1),
                  border: Border.all(
                    color: isSelected ? color : color.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  score > 0 ? '+$score' : '$score',
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Container(
            key: ValueKey(selectedScore),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _colorForScore(selectedScore).withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              scoreDescriptions[selectedScore] ?? '',
              style: TextStyle(
                color: _colorForScore(selectedScore),
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
