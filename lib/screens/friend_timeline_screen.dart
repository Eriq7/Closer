// friend_timeline_screen.dart
// Shows a merged chronological timeline of all interactions and label changes
// for a single friend, sorted oldest-first (top = earliest event).

import 'package:flutter/material.dart';
import '../models/timeline_event.dart';
import '../services/interaction_service.dart';
import '../widgets/timeline_tile.dart';

class FriendTimelineScreen extends StatefulWidget {
  final String friendId;
  final String friendName;

  const FriendTimelineScreen({
    super.key,
    required this.friendId,
    required this.friendName,
  });

  @override
  State<FriendTimelineScreen> createState() => _FriendTimelineScreenState();
}

class _FriendTimelineScreenState extends State<FriendTimelineScreen> {
  final _interactionService = InteractionService();
  List<TimelineEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final interactions =
          await _interactionService.getInteractionsForFriend(widget.friendId);
      final labelChanges =
          await _interactionService.getLabelChangesForFriend(widget.friendId);

      final events = <TimelineEvent>[
        ...interactions.map(InteractionTimelineEvent.new),
        ...labelChanges.map(LabelChangeTimelineEvent.new),
      ]..sort((a, b) => a.createdAt.compareTo(b.createdAt)); // oldest first

      setState(() => _events = events);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.friendName} — Timeline'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? const Center(
                  child: Text(
                    'No events yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: _events.length,
                  itemBuilder: (context, index) => TimelineTile(
                    event: _events[index],
                    isFirst: index == 0,
                    isLast: index == _events.length - 1,
                  ),
                ),
    );
  }
}
