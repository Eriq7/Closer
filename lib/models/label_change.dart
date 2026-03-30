// label_change.dart
// Data model for a label change event (either system-triggered or manual).
// Maps to the `label_changes` table in Supabase.

import '../utils/constants.dart';

enum ChangeTriggeredBy { system, manual }

class LabelChange {
  final String id;
  final String friendId;
  final RelationshipLabel fromLabel;
  final RelationshipLabel toLabel;
  final ChangeTriggeredBy triggeredBy;
  final String? reason; // Required for manual changes
  final DateTime createdAt;

  const LabelChange({
    required this.id,
    required this.friendId,
    required this.fromLabel,
    required this.toLabel,
    required this.triggeredBy,
    this.reason,
    required this.createdAt,
  });

  factory LabelChange.fromMap(Map<String, dynamic> map) {
    return LabelChange(
      id: map['id'] as String,
      friendId: map['friend_id'] as String,
      fromLabel: RelationshipLabel.fromDb(map['from_label'] as String),
      toLabel: RelationshipLabel.fromDb(map['to_label'] as String),
      triggeredBy: map['triggered_by'] == 'manual'
          ? ChangeTriggeredBy.manual
          : ChangeTriggeredBy.system,
      reason: map['reason'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'friend_id': friendId,
      'from_label': fromLabel.dbValue,
      'to_label': toLabel.dbValue,
      'triggered_by': triggeredBy == ChangeTriggeredBy.manual ? 'manual' : 'system',
      if (reason != null) 'reason': reason,
    };
  }
}
