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
import 'why_it_works_screen.dart';

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
        title: GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WhyItWorksScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Closer',
                  style: GoogleFonts.caveat(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: CrayonColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                PhosphorIcon(PhosphorIconsThin.arrowRight,
                    size: 14, color: CrayonColors.responsiveLabelText),
                const SizedBox(width: 4),
                Text(
                  'Why it works',
                  style: GoogleFonts.caveat(
                    fontSize: 13,
                    color: CrayonColors.responsiveLabelText,
                    decoration: TextDecoration.underline,
                    decorationColor: CrayonColors.responsiveLabelText,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
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
                  ? _filter != null
                      ? Center(
                          child: Text(
                            'No ${_filter!.displayName} contacts.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.caveat(
                              color: CrayonColors.textHint,
                              fontSize: 19,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Get started in 3 steps',
                                style: GoogleFonts.caveat(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: CrayonColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _OnboardingStep(
                                number: '1',
                                text: 'Add a person you care about',
                              ),
                              const SizedBox(height: 10),
                              _OnboardingStep(
                                number: '2',
                                text: 'Log interactions and how they felt',
                              ),
                              const SizedBox(height: 10),
                              _OnboardingStep(
                                number: '3',
                                text: 'Watch your relationship patterns emerge',
                              ),
                              const SizedBox(height: 28),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/images/peak_end_rule.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Based on the Peak-End Rule — people remember how an experience ended, not the average.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.caveat(
                                  fontSize: 16,
                                  color: CrayonColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 28),
                              CrayonButton(
                                label: 'Add your first person',
                                icon: PhosphorIconsThin.userPlus,
                                seed: 42,
                                onPressed: () async {
                                  final added = await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                        builder: (_) => const AddFriendScreen()),
                                  );
                                  if (added == true) _load();
                                },
                              ),
                            ],
                          ),
                        )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: GestureDetector(
                              onTap: () => Navigator.of(context)
                                  .push(MaterialPageRoute(
                                      builder: (_) => const VisualizationScreen()))
                                  .then((_) => _load()),
                              child: CrayonCard(
                                seed: 101,
                                fillColor: CrayonColors.surfaceAlt,
                                strokeColor: CrayonColors.strokeLight,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    PhosphorIcon(PhosphorIconsThin.graph,
                                        size: 20,
                                        color: CrayonColors.textSecondary),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'View Relationship Map',
                                        style: GoogleFonts.caveat(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: CrayonColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    PhosphorIcon(PhosphorIconsThin.arrowRight,
                                        size: 16,
                                        color: CrayonColors.textHint),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        final friend = _filtered[index - 1];
                        return _FriendCard(
                          friend: friend,
                          index: index - 1,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    FriendDetailScreen(friendId: friend.id, friendName: friend.name),
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

class _OnboardingStep extends StatelessWidget {
  final String number;
  final String text;

  const _OnboardingStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CrayonCircle(
          fillColor: CrayonColors.accentPurple.withAlpha(60),
          strokeColor: CrayonColors.accentPurple,
          size: 32,
          seed: number.hashCode & 0xFF,
          child: Text(
            number,
            style: GoogleFonts.caveat(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: CrayonColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: GoogleFonts.caveat(
                fontSize: 18,
                color: CrayonColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
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
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                friend.name,
                style: GoogleFonts.caveat(
                  fontWeight: FontWeight.w700,
                  fontSize: 21,
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
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
