// label_override_dialog.dart
// Dialog shown when user tries to manually change a label.
// Enforces the two-step friction: acknowledge warning + write a mandatory reason.
// Returns the written reason string if confirmed, or null if cancelled.

import 'package:flutter/material.dart';
import '../utils/constants.dart';

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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'A note before you proceed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
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
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _warningAcknowledged,
              onChanged: (v) => setState(() => _warningAcknowledged = v ?? false),
              title: const Text(
                'I understand and want to proceed anyway',
                style: TextStyle(fontSize: 13),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            const Text(
              'Why do you want to change this label?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              enabled: _warningAcknowledged,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Required — write your reason here...',
                border: OutlineInputBorder(),
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
