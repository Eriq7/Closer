// friend_service.dart
// CRUD operations for friends. All queries are scoped to the current user via RLS.

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friend.dart';
import '../utils/constants.dart';

class FriendService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Friend>> getFriends() async {
    final data = await _client
        .from('friends')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => Friend.fromMap(e)).toList();
  }

  Future<Friend> addFriend({
    required String name,
    required RelationshipLabel label,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client.from('friends').insert({
      'user_id': userId,
      'name': name,
      'label': label.dbValue,
    }).select().single();
    return Friend.fromMap(data);
  }

  Future<Friend> updateLabel({
    required String friendId,
    required RelationshipLabel newLabel,
  }) async {
    final data = await _client
        .from('friends')
        .update({
          'label': newLabel.dbValue,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', friendId)
        .select()
        .single();
    return Friend.fromMap(data);
  }

  Future<void> deleteFriend(String friendId) async {
    await _client.from('friends').delete().eq('id', friendId);
  }
}
