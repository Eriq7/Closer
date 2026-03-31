// visualization_screen.dart
// Shows all friends as a concentric-circle relationship map.
// You are at the center; Active friends are on the innermost ring,
// Cut-off on the outermost. Tap a friend dot to navigate to their detail page.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friend.dart';
import '../services/friend_service.dart';
import '../widgets/relationship_graph_painter.dart';
import '../theme/crayon_theme.dart';
import 'friend_detail_screen.dart';

class VisualizationScreen extends StatefulWidget {
  const VisualizationScreen({super.key});

  @override
  State<VisualizationScreen> createState() => _VisualizationScreenState();
}

class _VisualizationScreenState extends State<VisualizationScreen> {
  final _friendService = FriendService();
  List<Friend> _friends = [];
  bool _loading = true;
  RelationshipGraphPainter? _painter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final friends = await _friendService.getFriends();
      final userId = Supabase.instance.client.auth.currentUser?.id;
      String name = '';
      if (userId != null) {
        final data = await Supabase.instance.client
            .from('profiles')
            .select('display_name')
            .eq('id', userId)
            .maybeSingle();
        name = (data?['display_name'] as String?) ?? '';
      }
      setState(() {
        _friends = friends;
        _painter = RelationshipGraphPainter(friends: friends, userName: name);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleTap(Offset localPosition) {
    final friend = _painter?.findFriendAt(localPosition);
    if (friend != null) {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => FriendDetailScreen(friendId: friend.id),
            ),
          )
          .then((_) => _load());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relationship Map')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _friends.isEmpty
              ? Center(
                  child: Text(
                    'Add some friends to see them here.',
                    style: GoogleFonts.caveat(
                      color: CrayonColors.textHint,
                      fontSize: 18,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: GestureDetector(
                            onTapDown: (d) =>
                                _handleTap(d.localPosition),
                            child: CustomPaint(
                              painter: _painter,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
