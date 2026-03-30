// friend.dart
// Data model for a friend/contact. Maps directly to the `friends` table in Supabase.

import '../utils/constants.dart';

class Friend {
  final String id;
  final String userId;
  final String name;
  final RelationshipLabel label;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Friend({
    required this.id,
    required this.userId,
    required this.name,
    required this.label,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      label: RelationshipLabel.fromDb(map['label'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'name': name,
      'label': label.dbValue,
    };
  }

  Friend copyWith({
    String? name,
    RelationshipLabel? label,
  }) {
    return Friend(
      id: id,
      userId: userId,
      name: name ?? this.name,
      label: label ?? this.label,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
