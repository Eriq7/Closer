# models/

Data classes that map directly to Supabase tables. All models are immutable and have `fromMap` (from DB row) and `toInsertMap` (for writes) methods.

| File | Table | Notes |
|------|-------|-------|
| `friend.dart` | `friends` | Carries current `RelationshipLabel` |
| `interaction.dart` | `interactions` | Score -3 to +3, optional note |
| `label_change.dart` | `label_changes` | Records every label transition (system or manual) |

Labels are defined as an enum in `utils/constants.dart` and stored as strings in Postgres.
