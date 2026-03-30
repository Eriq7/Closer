# Closer — Project Plan

## Overview
Relationship quantification management app for overseas Chinese users.
- **Stack**: Flutter + Supabase
- **Platforms**: iOS + Android (currently developing via Chrome/Web for MVP)
- **UI Language**: English only
- **Auth**: Email + password

---

## Business Rules Summary

### Scoring
- Range: -3 to +3 per interaction
- Optional note per interaction ("Why did you give this score?")

### Rolling Window (auto-determined by system)
- Average interaction interval ≤ 21 days → evaluate last **5** scores
- Average interaction interval > 21 days → evaluate last **3** scores

### Four Labels
| Label | Description |
|-------|-------------|
| Active | Core friends, proactively maintain |
| Responsive | Respond when reached out to, don't initiate |
| Obligatory | Want distance but maintain for practical reasons |
| Cut-off | No longer in contact |

- Adding a friend: user selects initial label (all 4 options available)
- Cut-off friends stay in list unless manually deleted

### Automatic Label Switching
- Score -3 → immediate Cut-off
- Score -2 → Active → Responsive; Responsive → Cut-off
- Window total -4/-5 → prompt: choose Responsive or Obligatory
- Responsive window total ≥ +2 → can upgrade to Active

### Manual Label Override
1. Warning shown: scoring history doesn't support this change
2. User must acknowledge warning
3. User must write mandatory reason
4. Label changes only after both steps

### Reminders
- Obligatory friends: re-evaluation every 2 months
- Active friends: push notification if no interaction for 3+ weeks (Phase 2)

---

## Phase 1: Core Scoring + Label Switching ✅
**Goal**: Working app with friend management, scoring, and auto label switching.

- [x] Step 1: Flutter project setup + Supabase connection
- [x] Step 2: Authentication (register, login, logout)
- [x] Step 3: Friend management (add, list, delete)
- [x] Step 4: Interaction scoring (score picker + optional note)
- [x] Step 5: Label engine (window calc + auto switching logic)
- [x] Step 6: Label change history display
- [x] Step 6b: Interaction edit + delete (with label re-evaluation)

## 🔍 CHECKPOINT — Phase 1 ✅
> Passed by user on 2026-03-29.

---

## Phase 2: Visualization + Timeline + Reminders
**Goal**: Full experience with visual relationship map, history timeline, and push notifications.

- [x] Step 7: Relationship visualization (concentric-circle map, tap to navigate)
- [x] Step 8: Per-friend relationship timeline (merged interactions + label changes)
- [x] Step 9: Push notifications (ReminderChecker + flutter_local_notifications, mobile only)

## 🔍 CHECKPOINT — Phase 2
> **STOP**. User reviews full feature set before any additional work.

---

## Progress Log
| Date | Milestone | Status |
|------|-----------|--------|
| 2026-03-29 | Plan created, business rules clarified | ✅ |
| 2026-03-29 | Flutter project created, all Phase 1 code written, 14/14 unit tests passing | ✅ |
| 2026-03-29 | Supabase tables created, app tested end-to-end in browser | ✅ |
| 2026-03-29 | Phase 1 complete (incl. interaction edit/delete, 20/20 unit tests) | ✅ |
| 2026-03-29 | Phase 2 complete (29/29 unit tests) | ✅ |
