// friend.dart
// Data model for a friend/contact. Maps directly to the `friends` table in Supabase.

import '../services/label_engine.dart';
import '../utils/constants.dart';

class Friend {
  final String id;
  final String userId;
  final String name;
  final RelationshipLabel label;
  final ContactFrequency contactFrequency;
  final LabelEvaluation? pendingEvaluation;
  final DateTime? windowAnchorAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Friend({
    required this.id,
    required this.userId,
    required this.name,
    required this.label,
    required this.contactFrequency,
    this.pendingEvaluation,
    this.windowAnchorAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      label: RelationshipLabel.fromDb(map['label'] as String),
      contactFrequency: ContactFrequency.fromDb(
          (map['contact_frequency'] as String?) ?? 'rarely'),
      pendingEvaluation: map['pending_evaluation'] != null
          ? _parsePendingEvaluation(
              map['pending_evaluation'] as Map<String, dynamic>)
          : null,
      windowAnchorAt: map['window_anchor_at'] != null
          ? DateTime.parse(map['window_anchor_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static LabelEvaluation _parsePendingEvaluation(Map<String, dynamic> json) {
    return LabelEvaluation(
      trigger: LabelTrigger.values.firstWhere(
        (t) => t.name == json['trigger'],
        orElse: () => LabelTrigger.none,
      ),
      windowTotal: json['windowTotal'] as int,
      windowSize: json['windowSize'] as int,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'name': name,
      'label': label.dbValue,
      'contact_frequency': contactFrequency.dbValue,
    };
  }

  Friend copyWith({
    String? name,
    RelationshipLabel? label,
    ContactFrequency? contactFrequency,
    LabelEvaluation? pendingEvaluation,
    DateTime? windowAnchorAt,
  }) {
    return Friend(
      id: id,
      userId: userId,
      name: name ?? this.name,
      label: label ?? this.label,
      contactFrequency: contactFrequency ?? this.contactFrequency,
      pendingEvaluation: pendingEvaluation ?? this.pendingEvaluation,
      windowAnchorAt: windowAnchorAt ?? this.windowAnchorAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
