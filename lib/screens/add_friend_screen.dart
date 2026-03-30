// add_friend_screen.dart
// Screen for adding a new friend. User enters name and selects an initial label.
// All 4 labels are available as starting options.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/friend_service.dart';
import '../utils/constants.dart';
import '../widgets/label_badge.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  RelationshipLabel _selectedLabel = RelationshipLabel.responsive;
  final _friendService = FriendService();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _friendService.addFriend(
        name: _nameController.text.trim(),
        label: _selectedLabel,
      );
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add friend: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Person')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 28),
              const Text(
                'How would you categorize this relationship?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...RelationshipLabel.values.map(
                (label) => RadioListTile<RelationshipLabel>(
                  value: label,
                  groupValue: _selectedLabel,
                  onChanged: (v) => setState(() => _selectedLabel = v!),
                  title: Row(
                    children: [
                      Text(label.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      LabelBadge(label: label, small: true),
                    ],
                  ),
                  subtitle: Text(
                    label.description,
                    style: const TextStyle(fontSize: 12),
                  ),
                  contentPadding: EdgeInsets.zero,
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
                    : const Text('Add Person'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
