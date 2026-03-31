// home_screen.dart
// Main screen: lists all friends grouped by label with filter tabs.
// Crayon storybook style: CrayonCard friend cards, CrayonChip filter tabs, Phosphor icons.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/friend.dart';
import '../services/auth_service.dart';
import '../services/friend_service.dart';
import '../utils/constants.dart';
import '../services/notification_service.dart';
import '../widgets/label_badge.dart';
import '../theme/crayon_theme.dart';
import '../theme/crayon_widgets.dart';
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
  RelationshipLabel? _filter;

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
            icon: PhosphorIcon(PhosphorIconsThin.graph,
                size: 22, color: CrayonColors.textPrimary),
            tooltip: 'Relationship Map',
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(
                    builder: (_) => const VisualizationScreen()))
                .then((_) => _load()),
          ),
          IconButton(
            icon: PhosphorIcon(PhosphorIconsThin.signOut,
                size: 22, color: CrayonColors.textPrimary),
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
                      onTap: () =>
                          setState(() => _filter = _filter == l ? null : l),
                      labelKey: l,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: CrayonButton(
        label: 'Add Person',
        icon: PhosphorIconsThin.userPlus,
        seed: 200,
        onPressed: () async {
          final added = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddFriendScreen()),
          );
          if (added == true) _load();
        },
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
                          PhosphorIcon(
                            PhosphorIconsThin.users,
                            size: 64,
                            color: CrayonColors.textHint,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _filter == null
                                ? 'No people yet.\nTap + to add someone.'
                                : 'No ${_filter!.displayName} contacts.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.caveat(
                              color: CrayonColors.textHint,
                              fontSize: 18,
                            ),
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
                          index: index,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    FriendDetailScreen(friendId: friend.id),
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
  final int index;

  const _FriendCard({
    required this.friend,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final colors = labelCrayonColors(friend.label);

    return GestureDetector(
      onTap: onTap,
      child: CrayonCard(
        seed: index * 31 + 7,
        fillColor: CrayonColors.surface,
        strokeColor: CrayonColors.strokeLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CrayonCircle(
              fillColor: colors.fill.withAlpha(100),
              strokeColor: colors.border,
              size: 44,
              seed: friend.name.hashCode & 0xFF,
              child: Text(
                friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                style: GoogleFonts.caveat(
                  color: colors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                friend.name,
                style: GoogleFonts.caveat(
                  fontWeight: FontWeight.w700,
                  fontSize: 19,
                  color: CrayonColors.textPrimary,
                ),
              ),
            ),
            LabelBadge(label: friend.label, small: true),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final RelationshipLabel? labelKey;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.labelKey,
  });

  @override
  Widget build(BuildContext context) {
    Color fill;
    Color stroke;
    Color textColor;

    if (selected) {
      if (labelKey != null) {
        final colors = labelCrayonColors(labelKey!);
        fill = colors.fill;
        stroke = colors.border;
        textColor = colors.text;
      } else {
        fill = CrayonColors.accentPurple;
        stroke = CrayonColors.accentPurple.withAlpha(180);
        textColor = CrayonColors.textPrimary;
      }
    } else {
      fill = CrayonColors.surfaceAlt;
      stroke = CrayonColors.strokeLight;
      textColor = CrayonColors.textSecondary;
    }

    return GestureDetector(
      onTap: onTap,
      child: CrayonChip(
        fillColor: fill,
        strokeColor: stroke,
        seed: label.hashCode & 0xFF,
        child: Text(
          label,
          style: GoogleFonts.caveat(
            color: textColor,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
