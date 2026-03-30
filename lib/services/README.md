# services/

Business logic and Supabase data access layer.

| File | Responsibility |
|------|---------------|
| `auth_service.dart` | Register, login, logout via Supabase Auth |
| `friend_service.dart` | CRUD for friends table |
| `interaction_service.dart` | Save interactions + fetch history + save label changes |
| `label_engine.dart` | **Pure Dart** — no Supabase. Evaluates scoring history and returns `LabelEvaluation` with trigger type. All business rules live here. |

## Data flow when logging an interaction
1. `AddInteractionScreen` calls `InteractionService.addInteraction()`
2. Service saves to DB, then fetches updated history
3. Service calls `LabelEngine.evaluate()` with latest interaction + full history
4. Returns `LabelEvaluation` to the screen
5. Screen shows appropriate dialog based on trigger type
6. If user confirms → `FriendService.updateLabel()` + `InteractionService.saveLabelChange()`
