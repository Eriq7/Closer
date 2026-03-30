# Closer — Test Plan

## Scope
Tests focus on the label engine (pure business logic, no Supabase calls needed).
Integration/UI tests are manual (described below).

---

## Unit Tests: Label Engine (`test/label_engine_test.dart`)

### Single-event rules
| # | Scenario | Expected trigger |
|---|----------|-----------------|
| 1 | Score -3, any label | `immediateCutOff` |
| 2 | Score -2, current label = Active | `immediateDowngrade` |
| 3 | Score -2, current label = Responsive | `immediateDowngrade` |
| 4 | Score -2, current label = Obligatory | `none` (no single-event rule for Obligatory) |
| 5 | Score -1, any label | No single-event trigger |

### Window size determination
| # | Avg interval | Expected window |
|---|-------------|-----------------|
| 6 | 7 days avg | 5 (high frequency) |
| 7 | 21 days avg (boundary) | 5 (high frequency, inclusive) |
| 8 | 22 days avg | 3 (low frequency) |
| 9 | Fewer than 2 interactions | 3 (default low) |

### Window total rules
| # | Scenario | Expected trigger |
|---|----------|-----------------|
| 10 | Responsive, window total = +2 | `windowPositiveUpgrade` |
| 11 | Responsive, window total = +3 | `windowPositiveUpgrade` |
| 12 | Any label, window total = -4 | `windowNegativeDowngrade` |
| 13 | Any label, window total = -5 | `windowNegativeDowngrade` |
| 14 | Any label, window total = -3 | `none` |

### Downgrade result
| # | Input label | Expected result |
|---|-------------|----------------|
| 15 | Active → downgrade | Responsive |
| 16 | Responsive → downgrade | Cut-off |
| 17 | Obligatory → downgrade | Cut-off |

---

## Manual Integration Tests (run in browser/simulator)

### Auth
- [ ] Register with new email → lands on Home
- [ ] Log out → redirected to Login
- [ ] Login with wrong password → error shown inline
- [ ] Login with correct credentials → lands on Home

### Friend Management
- [ ] Add friend with each of the 4 initial labels → appears in list correctly
- [ ] Filter by label → only matching friends shown
- [ ] Tap friend → opens detail screen
- [ ] Delete friend → removed from list, no orphan data

### Scoring
- [ ] Log interaction with score -3 → "Upgrade/Change Suggested" dialog appears offering Cut-off
- [ ] Log interaction with score -2 on Active friend → dialog offers Responsive
- [ ] Log interaction, accumulate window total ≤-4 → downgrade prompt appears
- [ ] Log positive interactions on Responsive friend, window total ≥+2 → upgrade prompt
- [ ] Log neutral (0) interaction → no dialog, returns to detail screen
- [ ] Note is optional: save without note works fine
- [ ] Note is saved and displayed in interaction history

### Manual Label Override
- [ ] Change label manually → warning dialog appears
- [ ] Cannot confirm without checking the acknowledgment box
- [ ] Cannot confirm with empty reason field
- [ ] After filling both → label changes, reason recorded in history

### Label History
- [ ] System-triggered change shows "System" tag
- [ ] Manual change shows "Manual" tag and reason text

---

## Running Unit Tests
```
flutter test
```

## Running a Single Test File
```
flutter test test/label_engine_test.dart
```
