# Daily Life OS — SQLite (Drift) Dynamic Integration Plan

## Strategy
- **Zero UI changes** — only data wiring changes
- Use `drift` (type-safe SQLite ORM) + `drift_flutter` for platform binding
- Use `flutter_bloc` (already in deps) for BLoC state management per module
- Use `get_it` (already in deps) for dependency injection

---

## Phase 1 — Dependencies (pubspec.yaml)

Add:
```yaml
drift: ^2.21.0
drift_flutter: ^0.2.4
path_provider: ^2.1.5
path: ^1.9.0
```
dev_dependencies:
```yaml
drift_dev: ^2.21.0
build_runner: ^2.4.13
```

---

## Phase 2 — Database Schema (5 tables)

### `habits` table
| Column | Type | Notes |
|--------|------|-------|
| id | int PK | auto-increment |
| title | text | habit name |
| iconCodePoint | int | Icons.xxx.codePoint |
| colorValue | int | Color.value |
| streakDays | int | default 0 |
| isDoneToday | bool | reset daily |
| lastCompletedDate | text | ISO8601 |
| createdAt | text | ISO8601 |

### `timeline_items` table
| Column | Type | Notes |
|--------|------|-------|
| id | int PK | |
| time | text | "09:00 AM" |
| title | text | |
| category | text | |
| colorValue | int | |
| iconCodePoint | int | |
| isDone | bool | |
| action | text | |
| date | text | ISO8601 date |

### `transactions` table
| Column | Type | Notes |
|--------|------|-------|
| id | int PK | |
| title | text | |
| category | text | Food/Travel/Bills... |
| amount | real | |
| mode | text | UPI/Card/Cash |
| iconCodePoint | int | |
| date | text | ISO8601 |
| type | text | expense/income |

### `subscriptions` table
| Column | Type | Notes |
|--------|------|-------|
| id | int PK | |
| name | text | |
| amount | real | |
| renewalDate | text | ISO8601 |
| autoKillEnabled | bool | |
| iconCodePoint | int | |

### `iou_entries` table (Lend & Borrow)
| Column | Type | Notes |
|--------|------|-------|
| id | int PK | |
| person | text | |
| amount | real | |
| type | text | "lent"/"borrowed" |
| note | text | |
| date | text | ISO8601 |
| isSettled | bool | |

### `budget_settings` table
| Column | Type | Notes |
|--------|------|-------|
| id | int PK | always 1 |
| monthlyBudget | real | |
| fixedBills | real | |

### `notes` table
| Column | Type | Notes |
|--------|------|-------|
| id | int PK | |
| title | text | |
| content | text | |
| colorValue | int | |
| isPinned | bool | |
| tags | text | comma-separated |
| createdAt | text | ISO8601 |
| updatedAt | text | ISO8601 |

---

## Phase 3 — Data Layer per Feature

### Structure (each feature gets):
```
lib/features/<module>/
  data/
    datasources/  <module>_local_datasource.dart
    models/       <module>_model.dart (Drift table row ↔ entity)
    repositories/ <module>_repository_impl.dart
  domain/
    entities/     <module>_entity.dart
    repositories/ <module>_repository.dart (abstract)
    usecases/     watch_<items>.dart, add_<item>.dart, toggle_<item>.dart
  presentation/
    bloc/         <module>_bloc.dart, _event.dart, _state.dart
    pages/        (existing — UI unchanged, now uses BLoC)
```

---

## Phase 4 — BLoC per Feature

### TodayHub BLoC
- Events: `LoadTodayHub`, `ToggleHabit(id)`, `ToggleTimelineItem(id)`
- States: `TodayHubLoading`, `TodayHubLoaded(habits, timelineItems, safeSpend)`

### MoneyManager BLoC
- Events: `LoadMoney`, `AddTransaction(...)`, `ToggleIou(id)`, `UpdateBudget(...)`
- States: `MoneyLoading`, `MoneyLoaded(transactions, subscriptions, ious, budget)`

### Planner BLoC (timeline-level)
- Events: `LoadPlanner`, `AddPlannerItem(...)`, `TogglePlannerItem(id)`

### Notes BLoC
- Events: `LoadNotes`, `AddNote(...)`, `UpdateNote(...)`, `DeleteNote(id)`, `PinNote(id)`
- States: `NotesLoading`, `NotesLoaded(notes)`

---

## Phase 5 — Seed Data

On first launch (empty DB), insert demo data so the UI shows populated state:
- 4 habits (Water, Vitamins, Read, Meditation)
- 4 timeline items
- 3 transactions + budget settings
- 3 subscriptions + 2 IOUs
- 2 sample notes

---

## Phase 6 — Wire UI (zero visual changes)

- Wrap feature pages with `BlocProvider`
- Replace `final List<Map> _habits = [...]` with `BlocBuilder` reading from state
- Replace `setState(...)` toggles with `context.read<Bloc>().add(Event(...))`

---

## Execution Order

1. `pubspec.yaml` — add drift deps
2. Create `lib/core/database/app_database.dart` (all tables)  
3. Run `dart run build_runner build`
4. Create domain entities + repository abstracts (shared core)
5. Implement data layer (local datasources + repo impls)
6. Implement use cases
7. Implement BLoCs (today_hub, money, planner, notes)
8. Wire BLoCs into UI pages
9. Register everything in `injection_container.dart`
10. Seed data on first launch
