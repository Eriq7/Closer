// friend_detail_screen.dart
// Displays a friend's current label, all past interactions, and label change history.
// Crayon storybook style: CrayonCard tiles, CrayonCircle score badges, CrayonButton FAB.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/friend.dart';
import '../models/interaction.dart';
import '../models/label_change.dart';
import '../services/friend_service.dart';
import '../services/interaction_service.dart';
import '../utils/constants.dart';
import '../widgets/label_badge.dart';
import '../widgets/label_override_dialog.dart';
import '../widgets/label_trigger_handler.dart';
import '../theme/crayon_theme.dart';
import '../theme/crayon_widgets.dart';
import 'add_interaction_screen.dart';
import 'edit_interaction_screen.dart';
import 'friend_timeline_screen.dart';

class FriendDetailScreen extends StatefulWidget {
  final String friendId;

  const FriendDetailScreen({super.key, required this.friendId});

  @override
  State<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends State<FriendDetailScreen> {
  final _friendService = FriendService();
  final _interactionService = InteractionService();

  Friend? _friend;
  List<Interaction> _interactions = [];
  List<LabelChange> _labelChanges = [];
  bool _loading = true;
  bool _labelHistoryExpanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final friends = await _friendService.getFriends();
      _friend = friends.firstWhere((f) => f.id == widget.friendId);
      _interactions =
          await _interactionService.getInteractionsForFriend(widget.friendId);
      _labelChanges =
          await _interactionService.getLabelChangesForFriend(widget.friendId);
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    if (mounted && _friend?.pendingEvaluation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await handleLabelTrigger(
          context: context,
          evaluation: _friend!.pendingEvaluation!,
          friend: _friend!,
          friendService: _friendService,
          interactionService: _interactionService,
        );
        if (mounted) _load();
      });
    }
  }

  Future<void> _manualLabelChange() async {
    if (_friend == null) return;
    final labels =
        RelationshipLabel.values.where((l) => l != _friend!.label).toList();

    final toLabel = await showDialog<RelationshipLabel>(
      context: context,
      builder: (_) => _LabelSelectDialog(
        currentLabel: _friend!.label,
        availableLabels: labels,
      ),
    );
    if (toLabel == null || !mounted) return;

    final reason = await LabelOverrideDialog.show(
      context,
      fromLabel: _friend!.label,
      toLabel: toLabel,
    );
    if (reason == null || !mounted) return;

    final fromLabel = _friend!.label;
    await _friendService.updateLabel(
      friendId: _friend!.id,
      newLabel: toLabel,
    );
    await _interactionService.saveLabelChange(
      friendId: _friend!.id,
      fromLabel: fromLabel,
      toLabel: toLabel,
      triggeredBy: ChangeTriggeredBy.manual,
      reason: reason,
    );
    _load();
  }

  Future<void> _editInteraction(Interaction interaction) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            EditInteractionScreen(friend: _friend!, interaction: interaction),
      ),
    );
    if (updated == true) _load();
  }

  Future<void> _deleteInteraction(Interaction interaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this interaction?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: CrayonColors.scoreNegative2),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final evaluation = await _interactionService.deleteInteraction(
      interactionId: interaction.id,
      friendId: widget.friendId,
      currentLabel: _friend!.label,
      contactFrequency: _friend!.contactFrequency,
      windowAnchorAt: _friend!.windowAnchorAt,
    );

    if (!mounted) return;

    if (evaluation != null) {
      await handleLabelTrigger(
        context: context,
        evaluation: evaluation,
        friend: _friend!,
        friendService: _friendService,
        interactionService: _interactionService,
      );
    }

    _load();
  }

  Future<void> _changeFrequency() async {
    if (_friend == null) return;
    final chosen = await showDialog<ContactFrequency>(
      context: context,
      builder: (_) => _FrequencySelectDialog(current: _friend!.contactFrequency),
    );
    if (chosen == null || !mounted) return;
    await _friendService.updateContactFrequency(_friend!.id, chosen);
    _load();
  }

  Future<void> _deleteFriend() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove ${_friend?.name}?'),
        content: const Text(
          'This will permanently delete all interactions and history for this person.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: CrayonColors.scoreNegative2),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _friendService.deleteFriend(widget.friendId);
      context.pop();
    }
  }

  Future<void> _deleteLabelChange(LabelChange change) async {
    final isLatest =
        _labelChanges.isNotEmpty && _labelChanges.first.id == change.id;

    if (isLatest) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete this label change?'),
          content: Text(
            'This will revert the label from "${change.toLabel.displayName}" back to "${change.fromLabel.displayName}".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: CrayonColors.scoreNegative2),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete & Revert'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      await _interactionService.deleteLabelChange(change.id);
      await _friendService.updateLabel(
        friendId: widget.friendId,
        newLabel: change.fromLabel,
      );
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete this history entry?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: CrayonColors.scoreNegative2),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      await _interactionService.deleteLabelChange(change.id);
    }

    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_friend == null) {
      return const Scaffold(body: Center(child: Text('Not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_friend!.name),
        actions: [
          IconButton(
            icon: PhosphorIcon(PhosphorIconsThin.chartLine,
                size: 22, color: CrayonColors.textPrimary),
            tooltip: 'Timeline',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FriendTimelineScreen(
                  friendId: widget.friendId,
                  friendName: _friend!.name,
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'change_label') _manualLabelChange();
              if (v == 'change_frequency') _changeFrequency();
              if (v == 'delete') _deleteFriend();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'change_label',
                child: Text('Change label manually'),
              ),
              const PopupMenuItem(
                value: 'change_frequency',
                child: Text('Change contact frequency'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Remove person',
                  style: GoogleFonts.caveat(color: CrayonColors.scoreNegative2),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: CrayonButton(
        label: 'Log Interaction',
        icon: PhosphorIconsThin.plus,
        backgroundColor: CrayonColors.accentPurple,
        seed: 55,
        onPressed: () async {
          final updated = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => AddInteractionScreen(friend: _friend!),
            ),
          );
          if (updated == true) _load();
        },
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Current label row
            Row(
              children: [
                Text(
                  'Current label: ',
                  style: GoogleFonts.caveat(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: CrayonColors.textPrimary,
                  ),
                ),
                LabelBadge(label: _friend!.label),
              ],
            ),
            const SizedBox(height: 20),

            if (_interactions.isEmpty && _labelChanges.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No interactions yet.\nLog your first one!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.caveat(
                      color: CrayonColors.textHint,
                      fontSize: 19,
                    ),
                  ),
                ),
              ),

            // Interactions section
            if (_interactions.isNotEmpty) ...[
              CrayonSectionHeader('Interactions'),
              ..._interactions.mapIndexed((i, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _InteractionTile(
                      interaction: i,
                      index: index,
                      onEdit: () => _editInteraction(i),
                      onDelete: () => _deleteInteraction(i),
                    ),
                  )),
              const SizedBox(height: 20),
            ],

            // Label history section
            if (_labelChanges.isNotEmpty) ...[
              CrayonSectionHeader('Label History'),
              ...(_labelHistoryExpanded
                      ? _labelChanges
                      : _labelChanges.take(3).toList())
                  .mapIndexed((c, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _LabelChangeTile(
                          change: c,
                          index: index,
                          onDelete: () => _deleteLabelChange(c),
                        ),
                      )),
              if (_labelChanges.length > 3)
                TextButton(
                  onPressed: () => setState(
                      () => _labelHistoryExpanded = !_labelHistoryExpanded),
                  child: Text(
                    _labelHistoryExpanded
                        ? 'Show less'
                        : 'Show ${_labelChanges.length - 3} more',
                    style: GoogleFonts.caveat(
                        fontSize: 17, color: CrayonColors.textSecondary),
                  ),
                ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// Extension to get index in map
extension _IndexedIterable<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(T e, int i) transform) {
    var index = 0;
    return map((e) => transform(e, index++));
  }
}

class _InteractionTile extends StatelessWidget {
  final Interaction interaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int index;

  const _InteractionTile({
    required this.interaction,
    required this.onEdit,
    required this.onDelete,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final fill = scoreFillColor(interaction.score);
    final textCol = scoreTextColor(interaction.score);
    final label = interaction.score > 0
        ? '+${interaction.score}'
        : '${interaction.score}';

    return CrayonCard(
      seed: index * 11 + 3,
      fillColor: CrayonColors.surface,
      strokeColor: CrayonColors.strokeLight,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CrayonCircle(
            fillColor: fill.withAlpha(80),
            strokeColor: fill,
            size: 44,
            seed: interaction.score + 20,
            child: Text(
              label,
              style: GoogleFonts.caveat(
                color: textCol,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scoreDescriptions[interaction.score] ?? '',
                  style: GoogleFonts.caveat(
                    fontSize: 18,
                    color: CrayonColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (interaction.note != null &&
                    interaction.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    interaction.note!,
                    style: GoogleFonts.caveat(
                      fontSize: 17,
                      color: CrayonColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy')
                      .format(interaction.createdAt.toLocal()),
                  style: GoogleFonts.caveat(
                    fontSize: 15,
                    color: CrayonColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            iconSize: 26,
            icon: PhosphorIcon(PhosphorIconsBold.dotsThree,
                size: 26, color: CrayonColors.textPrimary),
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete',
                    style: GoogleFonts.caveat(
                        color: CrayonColors.scoreNegative2, fontSize: 17)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabelChangeTile extends StatelessWidget {
  final LabelChange change;
  final VoidCallback onDelete;
  final int index;

  const _LabelChangeTile({
    required this.change,
    required this.onDelete,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return CrayonCard(
      seed: index * 17 + 9,
      fillColor: CrayonColors.surfaceAlt,
      strokeColor: CrayonColors.strokeLight,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LabelBadge(label: change.fromLabel, small: true),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: PhosphorIcon(PhosphorIconsThin.arrowRight,
                    size: 14, color: CrayonColors.textSecondary),
              ),
              LabelBadge(label: change.toLabel, small: true),
              const Spacer(),
              Text(
                change.triggeredBy == ChangeTriggeredBy.manual
                    ? 'Manual'
                    : 'System',
                style: GoogleFonts.caveat(
                  fontSize: 15,
                  color: CrayonColors.textHint,
                ),
              ),
              PopupMenuButton<String>(
                iconSize: 26,
                icon: PhosphorIcon(PhosphorIconsBold.dotsThree,
                    size: 26, color: CrayonColors.textPrimary),
                onSelected: (v) {
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: GoogleFonts.caveat(
                            color: CrayonColors.scoreNegative2, fontSize: 17)),
                  ),
                ],
              ),
            ],
          ),
          if (change.reason != null && change.reason!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '"${change.reason}"',
              style: GoogleFonts.caveat(
                fontSize: 17,
                fontStyle: FontStyle.italic,
                color: CrayonColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM d, yyyy').format(change.createdAt.toLocal()),
            style: GoogleFonts.caveat(
              fontSize: 15,
              color: CrayonColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelSelectDialog extends StatefulWidget {
  final RelationshipLabel currentLabel;
  final List<RelationshipLabel> availableLabels;

  const _LabelSelectDialog({
    required this.currentLabel,
    required this.availableLabels,
  });

  @override
  State<_LabelSelectDialog> createState() => _LabelSelectDialogState();
}

class _LabelSelectDialogState extends State<_LabelSelectDialog> {
  late RelationshipLabel _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.availableLabels.first;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select New Label'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.availableLabels
            .map(
              (label) => RadioListTile<RelationshipLabel>(
                value: label,
                groupValue: _selected,
                onChanged: (v) => setState(() => _selected = v!),
                title: Text(label.displayName),
                subtitle: Text(label.description,
                    style: GoogleFonts.caveat(
                        fontSize: 16, color: CrayonColors.textSecondary)),
                contentPadding: EdgeInsets.zero,
              ),
            )
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Next'),
        ),
      ],
    );
  }
}

class _FrequencySelectDialog extends StatefulWidget {
  final ContactFrequency current;
  const _FrequencySelectDialog({required this.current});

  @override
  State<_FrequencySelectDialog> createState() => _FrequencySelectDialogState();
}

class _FrequencySelectDialogState extends State<_FrequencySelectDialog> {
  late ContactFrequency _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Contact Frequency'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ContactFrequency.values
            .map(
              (freq) => RadioListTile<ContactFrequency>(
                value: freq,
                groupValue: _selected,
                onChanged: (v) => setState(() => _selected = v!),
                title: Text(freq.displayName),
                subtitle: Text(
                  freq == ContactFrequency.often
                      ? 'Evaluate after 5 interactions'
                      : 'Evaluate after 3 interactions',
                  style: GoogleFonts.caveat(
                      fontSize: 16, color: CrayonColors.textSecondary),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            )
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
