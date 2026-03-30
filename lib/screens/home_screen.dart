// home_screen.dart
// Main screen: lists all friends grouped by label with filter tabs.
// Provides navigation to add friend, view friend detail, and log out.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/friend.dart';
import '../services/auth_service.dart';
import '../services/friend_service.dart';
import '../utils/constants.dart';
import '../services/notification_service.dart';
import '../widgets/label_badge.dart';
import 'add_friend_screen.dart';
import 'friend_detail_screen.dart';
import 'visualization_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _friendService = FriendService();
  final _authService = AuthService();
  List<Friend> _friends = [];
  bool _loading = true;
  RelationshipLabel? _filter; // null = show all

  @override
  void initState() {
    super.initState();
    _checkProfileThenLoad();
  }

  Future<void> _checkProfileThenLoad() async {
    final authService = AuthService();
    final hasProfile = await authService.hasProfile();
    if (!hasProfile && mounted) {
      context.go('/setup-name');
      return;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _friends = await _friendService.getFriends();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    // Check reminders in background after load (no-op on web).
    NotificationService.checkAndNotify();
  }

  List<Friend> get _filtered {
    if (_filter == null) return _friends;
    return _friends.where((f) => f.label == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Closer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.hub_outlined),
            tooltip: 'Relationship Map',
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(
                    builder: (_) => const VisualizationScreen()))
                .then((_) => _load()),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              if (mounted) context.go('/login');
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                const SizedBox(width: 8),
                ...RelationshipLabel.values.map(
                  (l) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: l.displayName,
                      selected: _filter == l,
                      onTap: () => setState(
                          () => _filter = _filter == l ? null : l),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddFriendScreen()),
          );
          if (added == true) _load();
        },
        child: const Icon(Icons.person_add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            _filter == null
                                ? 'No people yet.\nTap + to add someone.'
                                : 'No ${_filter!.displayName} contacts.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final friend = _filtered[index];
                        return _FriendCard(
                          friend: friend,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FriendDetailScreen(
                                    friendId: friend.id),
                              ),
                            );
                            _load();
                          },
                        );
                      },
                    ),
            ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final Friend friend;
  final VoidCallback onTap;

  const _FriendCard({required this.friend, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          child: Text(
            friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
          ),
        ),
        title: Text(friend.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: LabelBadge(label: friend.label, small: true),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
