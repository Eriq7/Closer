// interaction_service.dart
// CRUD for interactions and label changes. After saving a new interaction,
// runs the label engine and returns any triggered evaluation.
//
// Single-event triggers (-3, -2) are returned immediately for the caller to handle.
// Window-based triggers are saved as pending_evaluation on the friend row,
// and shown to the user when they return to the Friend Detail screen.

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
  /// Single-event evaluations (-3, -2) are returned for immediate handling.
  /// Window-based evaluations are saved to friends.pending_evaluation and
  /// LabelTrigger.none is returned so the caller does not show a dialog.
  Future<({Interaction interaction, LabelEvaluation evaluation})> addInteraction({
    required String friendId,
    required int score,
    String? note,
    required RelationshipLabel currentLabel,
    required ContactFrequency contactFrequency,
    DateTime? windowAnchorAt,
  }) async {
    final userId = _client.auth.currentUser!.id;

    final data = await _client.from('interactions').insert({
      'friend_id': friendId,
      'user_id': userId,
      'score': score,
      if (note != null && note.isNotEmpty) 'note': note,
    }).select().single();

    final interaction = Interaction.fromMap(data);
    final history = await getInteractionsForFriend(friendId);
    final filteredHistory = _filterByAnchor(history, windowAnchorAt);

    final evaluation = LabelEngine.evaluate(
      latestInteraction: interaction,
      allInteractions: filteredHistory,
      currentLabel: currentLabel,
      contactFrequency: contactFrequency,
    );

    return (
      interaction: interaction,
      evaluation: await _handleEvaluation(friendId, evaluation),
    );
  }

  /// Updates an interaction's score/note and re-evaluates the label engine.
  Future<({Interaction interaction, LabelEvaluation evaluation})> updateInteraction({
    required String interactionId,
    required String friendId,
    required int score,
    String? note,
    required RelationshipLabel currentLabel,
    required ContactFrequency contactFrequency,
    DateTime? windowAnchorAt,
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
    final filteredHistory = _filterByAnchor(history, windowAnchorAt);

    final evaluation = LabelEngine.evaluate(
      latestInteraction: history.first,
      allInteractions: filteredHistory,
      currentLabel: currentLabel,
      contactFrequency: contactFrequency,
    );

    return (
      interaction: interaction,
      evaluation: await _handleEvaluation(friendId, evaluation),
    );
  }

  /// Deletes an interaction and re-evaluates the label engine.
  /// Returns null if no interactions remain.
  Future<LabelEvaluation?> deleteInteraction({
    required String interactionId,
    required String friendId,
    required RelationshipLabel currentLabel,
    required ContactFrequency contactFrequency,
    DateTime? windowAnchorAt,
  }) async {
    await _client.from('interactions').delete().eq('id', interactionId);
    final history = await getInteractionsForFriend(friendId);

    if (history.isEmpty) return null;

    final filteredHistory = _filterByAnchor(history, windowAnchorAt);
    if (filteredHistory.isEmpty) return null;

    final evaluation = LabelEngine.evaluate(
      latestInteraction: filteredHistory.first,
      allInteractions: filteredHistory,
      currentLabel: currentLabel,
      contactFrequency: contactFrequency,
    );

    return _handleEvaluation(friendId, evaluation);
  }

  /// Filters interactions to only those after [anchor]. If null, returns all.
  List<Interaction> _filterByAnchor(
      List<Interaction> history, DateTime? anchor) {
    if (anchor == null) return history;
    return history.where((i) => i.createdAt.isAfter(anchor)).toList();
  }

  /// For window-based triggers: saves to pending_evaluation and returns none.
  /// For single-event triggers or none: returns the evaluation unchanged.
  Future<LabelEvaluation> _handleEvaluation(
      String friendId, LabelEvaluation evaluation) async {
    if (evaluation.trigger == LabelTrigger.windowNegativeDowngrade ||
        evaluation.trigger == LabelTrigger.windowPositiveUpgrade) {
      await _client.from('friends').update({
        'pending_evaluation': {
          'trigger': evaluation.trigger.name,
          'windowTotal': evaluation.windowTotal,
          'windowSize': evaluation.windowSize,
        },
      }).eq('id', friendId);
      return const LabelEvaluation(
          trigger: LabelTrigger.none, windowTotal: 0, windowSize: 0);
    }
    return evaluation;
  }

  Future<List<LabelChange>> getLabelChangesForFriend(String friendId) async {
    final data = await _client
        .from('label_changes')
        .select()
        .eq('friend_id', friendId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => LabelChange.fromMap(e)).toList();
  }

  Future<void> deleteLabelChange(String id) async {
    await _client.from('label_changes').delete().eq('id', id);
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
