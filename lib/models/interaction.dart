// interaction.dart
// Data model for a single scored interaction with a friend.
// Maps to the `interactions` table in Supabase.

class Interaction {
  final String id;
  final String friendId;
  final String userId;
  final int score; // -3 to +3
  final String? note;
  final DateTime createdAt;

  const Interaction({
    required this.id,
    required this.friendId,
    required this.userId,
    required this.score,
    this.note,
    required this.createdAt,
  });

  factory Interaction.fromMap(Map<String, dynamic> map) {
    return Interaction(
      id: map['id'] as String,
      friendId: map['friend_id'] as String,
      userId: map['user_id'] as String,
      score: map['score'] as int,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'friend_id': friendId,
      'user_id': userId,
      'score': score,
      if (note != null && note!.isNotEmpty) 'note': note,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'score': score,
      'note': (note != null && note!.isNotEmpty) ? note : null,
    };
  }

  Interaction copyWith({int? score, String? note}) {
    return Interaction(
      id: id,
      friendId: friendId,
      userId: userId,
      score: score ?? this.score,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }
}
