// label_override_dialog.dart
// Dialog shown when user tries to manually change a label.
// Enforces the two-step friction: acknowledge warning + write a mandatory reason.
// Returns the written reason string if confirmed, or null if cancelled.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../utils/constants.dart';
import '../theme/crayon_theme.dart';
import '../theme/crayon_widgets.dart';

class LabelOverrideDialog extends StatefulWidget {
  final RelationshipLabel fromLabel;
  final RelationshipLabel toLabel;

  const LabelOverrideDialog({
    super.key,
    required this.fromLabel,
    required this.toLabel,
  });

  static Future<String?> show(
    BuildContext context, {
    required RelationshipLabel fromLabel,
    required RelationshipLabel toLabel,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LabelOverrideDialog(
        fromLabel: fromLabel,
        toLabel: toLabel,
      ),
    );
  }

  @override
  State<LabelOverrideDialog> createState() => _LabelOverrideDialogState();
}

class _LabelOverrideDialogState extends State<LabelOverrideDialog> {
  bool _warningAcknowledged = false;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm =
        _warningAcknowledged && _reasonController.text.trim().isNotEmpty;

    return AlertDialog(
      title: const Text('Change Label Manually'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CrayonCard(
              fillColor: CrayonColors.warningOrange.withValues(alpha: 0.3),
              strokeColor: CrayonColors.warningOrange,
              seed: 42,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIconsThin.warning,
                        color: CrayonColors.obligatoryLabelText,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'A note before you proceed',
                        style: GoogleFonts.caveat(
                          fontWeight: FontWeight.w700,
                          color: CrayonColors.obligatoryLabelText,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your scoring history doesn\'t support changing '
                    '${widget.fromLabel.displayName} → ${widget.toLabel.displayName}. '
                    'For your own protection, following the system\'s logic '
                    'is usually better than acting on feelings in the moment.',
                    style: GoogleFonts.caveat(
                      fontSize: 15,
                      color: CrayonColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _warningAcknowledged,
              onChanged: (v) => setState(() => _warningAcknowledged = v ?? false),
              title: Text(
                'I understand and want to proceed anyway',
                style: GoogleFonts.caveat(fontSize: 15),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            Text(
              'Why do you want to change this label?',
              style: GoogleFonts.caveat(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: CrayonColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              enabled: _warningAcknowledged,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Required — write your reason here...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canConfirm
              ? () => Navigator.of(context).pop(_reasonController.text.trim())
              : null,
          child: const Text('Change Label'),
        ),
      ],
    );
  }
}
