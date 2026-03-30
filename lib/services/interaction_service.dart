// interaction_service.dart
// CRUD for interactions and label changes. After saving a new interaction,
// runs the label engine and returns any triggered evaluation.

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/interaction.dart';
import '../models/label_change.dart';
import '../utils/constants.dart';
import 'label_engine.dart';

class InteractionService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Interaction>> getInteractionsForFriend(String friendId) async {
    final data = await _client
        .from('interactions')
        .select()
        .eq('friend_id', friendId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Interaction.fromMap(e)).toList();
  }

  /// Saves a new interaction and runs the label engine.
  /// Returns the evaluation result so the caller can show a dialog if needed.
  Future<({Interaction interaction, LabelEvaluation evaluation})> addInteraction({
    required String friendId,
    required int score,
    String? note,
    required RelationshipLabel currentLabel,
  }) async {
    final userId = _client.auth.currentUser!.id;

    // Save interaction.
    final data = await _client.from('interactions').insert({
      'friend_id': friendId,
      'user_id': userId,
      'score': score,
      if (note != null && note.isNotEmpty) 'note': note,
    }).select().single();

    final interaction = Interaction.fromMap(data);

    // Fetch history (newest-first) for window calculation.
    final history = await getInteractionsForFriend(friendId);

    final evaluation = LabelEngine.evaluate(
      latestInteraction: interaction,
      allInteractions: history,
      currentLabel: currentLabel,
    );

    return (interaction: interaction, evaluation: evaluation);
  }

  /// Updates an interaction's score/note and re-evaluates the label engine.
  Future<({Interaction interaction, LabelEvaluation evaluation})> updateInteraction({
    required String interactionId,
    required String friendId,
    required int score,
    String? note,
    required RelationshipLabel currentLabel,
  }) async {
    final data = await _client
        .from('interactions')
        .update({
          'score': score,
          'note': (note != null && note.isNotEmpty) ? note : null,
        })
        .eq('id', interactionId)
        .select()
        .single();

    final interaction = Interaction.fromMap(data);
    final history = await getInteractionsForFriend(friendId);

    final evaluation = LabelEngine.evaluate(
      latestInteraction: history.first,
      allInteractions: history,
      currentLabel: currentLabel,
    );

    return (interaction: interaction, evaluation: evaluation);
  }

  /// Deletes an interaction and re-evaluates the label engine.
  /// Returns null if no interactions remain (nothing to evaluate).
  Future<LabelEvaluation?> deleteInteraction({
    required String interactionId,
    required String friendId,
    required RelationshipLabel currentLabel,
  }) async {
    await _client.from('interactions').delete().eq('id', interactionId);
    final history = await getInteractionsForFriend(friendId);

    if (history.isEmpty) return null;

    return LabelEngine.evaluate(
      latestInteraction: history.first,
      allInteractions: history,
      currentLabel: currentLabel,
    );
  }

  Future<List<LabelChange>> getLabelChangesForFriend(String friendId) async {
    final data = await _client
        .from('label_changes')
        .select()
        .eq('friend_id', friendId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => LabelChange.fromMap(e)).toList();
  }

  Future<LabelChange> saveLabelChange({
    required String friendId,
    required RelationshipLabel fromLabel,
    required RelationshipLabel toLabel,
    required ChangeTriggeredBy triggeredBy,
    String? reason,
  }) async {
    final data = await _client.from('label_changes').insert({
      'friend_id': friendId,
      'from_label': fromLabel.dbValue,
      'to_label': toLabel.dbValue,
      'triggered_by': triggeredBy == ChangeTriggeredBy.manual ? 'manual' : 'system',
      if (reason != null) 'reason': reason,
    }).select().single();
    return LabelChange.fromMap(data);
  }
}
