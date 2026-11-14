# 📘 Daily Life OS — Project Knowledge Base

> **Purpose of this file:** a single place where any developer (or AI assistant) can learn
> how this project is built, how data flows, where things live, and what is real vs. mocked.
> Read this before touching the code.
>
> _Last updated: 2026-10-31 (branch `implement_branch`)_

---

## Table of Contents

1. [What the App Is](#1-what-the-app-is)
2. [Tech Stack](#2-tech-stack)
3. [Folder Structure](#3-folder-structure)
4. [Architecture (Clean Architecture + BLoC)](#4-architecture-clean-architecture--bloc)
5. [App Startup Flow](#5-app-startup-flow)
6. [Dependency Injection](#6-dependency-injection)
7. [Navigation & Screen Layout](#7-navigation--screen-layout)
8. [Database (Drift / SQLite)](#8-database-drift--sqlite)
9. [Other Storage (SharedPreferences & Secure Storage)](#9-other-storage-sharedpreferences--secure-storage)
10. [Notifications](#10-notifications)
11. [Feature Modules — Deep Dive](#11-feature-modules--deep-dive)
    - [Today Hub](#111-today-hub)
    - [Planner (Reminders, Pomodoro, Countdowns)](#112-planner-reminders-pomodoro-countdowns)
    - [Money Manager](#113-money-manager)
    - [Notes](#114-notes)
    - [Vault](#115-vault)
    - [Security (PIN / Pattern / Biometrics / Decoy)](#116-security-pin--pattern--biometrics--decoy)
12. [Shared Core Code](#12-shared-core-code)
13. [Theme & Design System](#13-theme--design-system)
14. [Platform Configuration](#14-platform-configuration)
15. [Testing](#15-testing)
16. [CI/CD](#16-cicd)
17. [Real vs. Mocked — Implementation Status](#17-real-vs-mocked--implementation-status)
18. [Known Issues & Tech Debt](#18-known-issues--tech-debt)
19. [How-To Recipes](#19-how-to-recipes)
20. [Glossary](#20-glossary)
21. [Other Docs in the Repo](#21-other-docs-in-the-repo)

---

## 1. What the App Is

**Daily Life OS** is an all-in-one personal utility app built in Flutter. It brings together:

| Pillar | Module | What it does |
|---|---|---|
| ⏱ Time | **Planner** | Reminders (recurring, priorities, checklists), Pomodoro focus timer, countdowns to important dates |
| 💰 Money | **Money Manager** | Expenses, monthly budget, "safe to spend per day", subscriptions, IOUs (lend/borrow) |
| 🧠 Mind | **Notes** | Colored, pinnable, tagged notes + a scratchpad |
| 🔒 Security | **Vault** + **Security** | Passwords/documents behind PIN, pattern, or biometric lock with a decoy mode |
| 🏠 Hub | **Today Hub** | Dashboard: habits with streaks, today's timeline, spend meter, audio briefing |

**Design principles** (from the PRD): offline-first, input in under 3 seconds (voice/type/scan),
modules that talk to each other, and privacy.

**Current reality:** 100% offline. There is **no backend**. All data is on the device.

---

## 2. Tech Stack

| Concern | Package | Notes |
|---|---|---|
| Language / SDK | Dart `^3.12.2`, Flutter `3.44.6` stable | Version pinned in CI |
| State management | `flutter_bloc ^9.1.1` | One Bloc per feature (except Security) |
| Dependency injection | `get_it ^9.2.1` | Global locator `sl` |
| Routing | `go_router ^14.2.7` | Only one route right now |
| Local DB | `drift ^2.21.0` + `drift_flutter` | SQLite; codegen via `build_runner` |
| Key-value storage | `shared_preferences` | Countdowns, notes scratchpad |
| Secure storage | `flutter_secure_storage` | PIN/pattern hashes, security flags |
| Biometrics | `local_auth ^3.0.2` | Fingerprint / Face ID |
| Hashing | `crypto` | SHA-256 + salt |
| Notifications | `flutter_local_notifications ^22.3.2` + `timezone` | Scheduled and instant |
| Env config | `flutter_dotenv` | `.env` keys: `API_BASE_URL`, `APP_ENV`, `APP_NAME` |
| Networking (unused) | `dio` | Ready but not used by any feature |
| Functional types (unused) | `dartz`, `equatable` | `equatable` is used; `dartz` `Either` is not |
| Misc | `intl`, `image_picker`, `permission_handler`, `path_provider`, `flutter_tts` | |
| Testing | `flutter_test`, `bloc_test`, `mocktail` | |
| Lint | `flutter_lints ^6.0.0` | `analysis_options.yaml` uses defaults |
| Font | Inter (variable) | `assets/fonts/Inter-Variable.ttf` |

---

## 3. Folder Structure

```
lib/
├── main.dart                         # Entry point (startup sequence)
├── config/
│   ├── routes/app_router.dart        # GoRouter: single route "/"
│   └── theme/                        # Colors, text styles, spacing, radius, decorations, ThemeData
├── core/
│   ├── constants/                    # app_constants, string_constants, asset_paths
│   ├── database/
│   │   ├── app_database.dart         # Drift tables + DB class (schema v2)
│   │   ├── app_database.g.dart       # GENERATED — never edit by hand
│   │   └── database_seeder.dart      # Demo data on first launch
│   ├── error/                        # exceptions.dart, failures.dart (mostly unused)
│   ├── network/                      # Dio ApiClient + interceptors (UNUSED today)
│   ├── notifications/notification_service.dart
│   ├── usecase/usecase.dart          # Base UseCase<T, Params> (UNUSED by features)
│   ├── utils/                        # date_utils, validators, snackbar_utils
│   └── widgets/                      # Reusable UI (buttons, sheets, loaders, quick capture…)
├── di/injection_container.dart       # get_it registrations
└── features/
    ├── navigation/                   # MainNavigationShell (bottom nav + quick-capture bar)
    ├── home/                         # HomePage — LEGACY, not referenced anywhere
    ├── today_hub/   { data, domain, presentation }
    ├── planner/     { data, domain, presentation(+widgets) }
    ├── money/       { data, domain, presentation }
    ├── notes/       { data, domain, presentation }
    ├── vault/       { data, domain, presentation }
    └── security/    { data, domain, presentation/widgets }   # no Bloc

test/                                 # mirrors lib/ structure
.github/workflows/                    # ci.yml, release.yml
```

Every feature folder follows the same pattern:

```
feature/
├── data/
│   ├── datasources/   xxx_local_datasource.dart   (abstract + Impl; talks to Drift)
│   ├── models/        xxx_model.dart              (extends Entity; fromDrift/fromEntity/fromJson)
│   └── repositories/  xxx_repository_impl.dart    (implements domain repo; delegates to datasource)
├── domain/
│   ├── entities/      xxx_entity.dart             (pure Equatable classes + computed getters)
│   ├── repositories/  xxx_repository.dart         (abstract contract)
│   └── usecases/      *_usecase.dart              (one class per action, callable via call())
└── presentation/
    ├── bloc/          xxx_bloc.dart / _event.dart / _state.dart
    ├── pages/         xxx_page.dart
    └── widgets/       (feature-specific widgets)
```

---

## 4. Architecture (Clean Architecture + BLoC)

### Layer diagram

```
┌──────────────────────────────────────────────────────────────┐
│ PRESENTATION   Page ─► BlocProvider(sl<XBloc>()..add(LoadX)) │
│                Widgets dispatch Events ─► Bloc emits States   │
└───────────────────────────────┬──────────────────────────────┘
                                │ calls
┌───────────────────────────────▼──────────────────────────────┐
│ DOMAIN         UseCase.call()  ─►  Repository (abstract)     │
│                Entities (pure Dart + Equatable)               │
└───────────────────────────────┬──────────────────────────────┘
                                │ implemented by
┌───────────────────────────────▼──────────────────────────────┐
│ DATA           RepositoryImpl ─► LocalDataSourceImpl          │
│                Models (Entity ⇄ Drift row)                    │
└───────────────────────────────┬──────────────────────────────┘
                                │
                     AppDatabase (Drift/SQLite)
```

### Conventions that hold across the codebase

- **Use cases return plain `Future<T>`.** They do *not* return `Either<Failure, T>`,
  even though `core/usecase/usecase.dart` defines that base class.
- **Errors** are caught in the Bloc (`try/catch` → `XError(e.toString())`), and only in the
  `Load` handlers for most features. Mutation handlers (add/delete/toggle) usually have **no try/catch**.
- **Reload after mutate:** after any write, the Bloc re-fetches the entire list and emits a new
  `XLoaded`. There are no optimistic updates.
- **States:** `XInitial → XLoading → XLoaded | XError`.
- **Bloc files** re-export their event/state files (`export 'x_event.dart';`), so importing the
  bloc file gives you everything.
- **Blocs are `registerFactory`.** Each page creates its own Bloc instance. Blocs are **not
  shared across tabs**, so a change in one tab does not refresh another tab's Bloc automatically.
- Repositories/use cases/data sources are `registerLazySingleton`.
- Dates are stored as **ISO-8601 strings** (`'2026-10-31'` or the full timestamp), not DateTime columns.
- Colors and icons are stored as ints (`colorValue` = ARGB32, `iconCodePoint` = Material icon
  code point) and rebuilt with `Color(v)` / `IconData(cp, fontFamily: 'MaterialIcons')`.

---

## 5. App Startup Flow

`lib/main.dart`:

```
main()
 ├─ WidgetsFlutterBinding.ensureInitialized()
 ├─ dotenv.load('.env')                         (errors ignored)
 ├─ await initDependencies()                    (lib/di/injection_container.dart)
 ├─ NotificationService.initialize()            (timezones + Android channels)
 │   └─ requestPermissions()                    (Android 13+ / iOS prompt)
 ├─ DatabaseSeeder.seedIfEmpty(db)              (only if the habits table is empty)
 └─ runApp(DailyLifeOSApp(router: createRouter()))
        └─ MaterialApp.router
             theme: AppTheme.lightTheme / darkTheme, themeMode: system
             route "/" → MainNavigationShell
```

Each startup step is wrapped in `try/catch` with `debugPrint`, so a failure in notifications or
seeding never stops the app from launching.

`DailyLifeOSApp` takes an optional `router` so tests can inject one.

---

## 6. Dependency Injection

File: `lib/di/injection_container.dart`. Global: `final sl = GetIt.instance;`

```dart
Future<void> initDependencies({
  AppDatabase? database,                 // tests pass AppDatabase(NativeDatabase.memory())
  NotificationService? notificationService,  // tests pass FakeNotificationService
  FlutterSecureStorage? secureStorage,
  LocalAuthentication? localAuth,
})
```

- If called again (as tests do), it calls `sl.reset()` first.
- Registration order: Core services → Database → DataSources → Repositories → UseCases → Blocs.

| Type | Lifetime |
|---|---|
| `NotificationService`, `AppDatabase` | Lazy singleton |
| All `*LocalDataSource`, `*Repository`, `*UseCase` | Lazy singleton |
| `TodayHubBloc`, `PlannerBloc`, `MoneyBloc`, `NotesBloc`, `VaultBloc` | **Factory** (new per page) |
| Security | No Bloc; widgets get `sl<SecurityRepository>()` directly |

UI code also calls `sl<NotificationService>()` and, in Notes, `sl<AppDatabase>()` directly.

---

## 7. Navigation & Screen Layout

- `config/routes/app_router.dart`: a single `GoRoute('/')` → `MainNavigationShell`.
  Sheets and dialogs use `showModalBottomSheet` / `Navigator.pop`, not go_router.
- `features/navigation/presentation/pages/main_navigation_shell.dart`:
  - `IndexedStack` holding 5 pages, **all built at startup and kept alive**:

    | Index | Tab | Page | Accent color |
    |---|---|---|---|
    | 0 | Today | `TodayHubPage` | `AppColors.primary` (indigo) |
    | 1 | Planner | `PlannerPage` | `moduleTime` (amber) |
    | 2 | Money | `MoneyManagerPage` | `moduleMoney` (emerald) |
    | 3 | Notes | `NotesPage` | `moduleNotes` (sky) |
    | 4 | Vault | `VaultPage` | `moduleVault` (violet) |

  - **Movable, Minimizable Floating Quick-Capture Ball (`FloatingQuickBall`)** (persists 2D screen coordinates in `SharedPreferences` and smoothly morphs between a 54×54 compact Quick Ball and the expanded 3-action capsule: `Hold to Speak`, `Quick Type`, `Scan`, plus a `Minimize` button). Tapping any action opens `QuickCaptureSheet.show(context, mode: …)` with smart NLP intent detection and real Drift SQLite persistence across Money, Planner, Today Habits, and Notes.

---

## 8. Database (Drift / SQLite)

File: `lib/core/database/app_database.dart` · DB name: `daily_life_os` · **schemaVersion = 2**

On web, Drift uses `sqlite3.wasm` + `drift_worker.js` from `web/`.

### Tables

#### `Habits`
| Column | Type | Notes |
|---|---|---|
| id | int PK auto | |
| title | text | |
| iconCodePoint, colorValue | int | |
| streakDays | int (0) | +1 on check, −1 on uncheck |
| isDoneToday | bool (false) | ⚠️ never reset at midnight |
| lastCompletedDate | text? | ISO date |
| createdAt | text | |

#### `TimelineItems` (Today Hub feed — separate from the planner)
`id, time (text, e.g. '09:00 AM'), title, category, colorValue, iconCodePoint, isDone, action (text label for the action button), date (ISO date)`

#### `Transactions`
`id, title, category, amount (real), mode ('UPI'|'Card'|'Cash'), iconCodePoint, date (full ISO timestamp), type ('expense'|'income', default 'expense')`

#### `BudgetSettings` (single row, id = 1)
`id (PK, default 1), monthlyBudget (default 40000), fixedBills (default 8000)`

#### `Subscriptions`
`id, name, amount, renewalDate (ISO), autoKillEnabled (bool), iconCodePoint`

#### `IouEntries`
`id, person, amount, type ('lent'|'borrowed'), note, date, isSettled (bool)`

#### `Notes`
`id, title, content, colorValue, isPinned, tags (comma-separated text), createdAt, updatedAt`

#### `PlannerItems` (the richest table)
| Column | Type / default | Meaning |
|---|---|---|
| id | int PK auto | |
| title | text | |
| date | text | **Start date**, `yyyy-MM-dd` (always truncated to 10 chars) |
| startTime / endTime | text? | e.g. `'09:00 AM'` |
| category | text | `'Work'`, `'Personal'`, `'Health'`, `'Notes'`… |
| colorValue, iconCodePoint | int | |
| isDone | bool (false) | Used **only for non-recurring** items |
| notes | text ('') | |
| repeatType | text ('none') | `none / daily / weekdays / weekly / monthly` *(v2)* |
| repeatDays | text ('') | `'1,3,5'` = Mon, Wed, Fri (ISO weekday 1–7) *(v2)* |
| endDate | text? | Recurrence end (`yyyy-MM-dd`), null = forever *(v2)* |
| priority | text ('medium') | `low / medium / high / urgent` *(v2)* |
| reminderOffsetMinutes | int (0) | 0, 5, 15, 30, 60, 1440 *(v2)* |
| checklistJson | text ('[]') | JSON `[{id,title,isDone}]` *(v2)* |
| completedDates | text ('') | `'2026-10-24,2026-10-25'`: per-day done flags for **recurring** items *(v2)* |

### Migrations
```dart
onCreate: m.createAll()
onUpgrade: if (from < 2) addColumn(plannerItems, …7 new columns…)
```
**When you change a table:** bump `schemaVersion`, add an `if (from < N)` block, then run
`dart run build_runner build --delete-conflicting-outputs` to regenerate `app_database.g.dart`.

### Seeder (`database_seeder.dart`)
Runs only when `habits` is empty. It inserts:
- Habits: *Drink 3L Water, Daily Vitamins, Read 15 mins, Meditation (10m)*
- Timeline (today): *Morning Standup & Deep Focus, Electricity Bill Due (₹450), Call Bank re: Card Upgrade, Sarah's Birthday Gift Planning*
- Budget row, Transactions (*Organic Grocery, Metro Card Recharge, Fiber Internet Bill*)
- Subscriptions (*Netflix 4K, Spotify, GitHub Copilot*), IOUs (*David Kumar, Priya Sen*)
- Notes (*Sarah's Birthday Gift Ideas, Weekly Goals*), Planner (*Morning Standup, Gym Workout*)

---

## 9. Other Storage (SharedPreferences & Secure Storage)

| Store | Key | Owner | Content |
|---|---|---|---|
| SharedPreferences | `planner_saved_countdowns` | `planner_page.dart` | JSON list of `CountdownItemModel` |
| SharedPreferences | (scratchpad key in `notes_page.dart`) | Notes | Scratchpad text |
| Secure storage | `vault_sec_salt` | Security | 32-byte random salt (base64url) |
| Secure storage | `vault_sec_pin_hash`, `vault_sec_decoy_pin_hash` | Security | SHA-256(salt:pin) |
| Secure storage | `vault_sec_pattern_hash`, `vault_sec_decoy_pattern_hash` | Security | SHA-256(salt:"0-1-2-5-8") |
| Secure storage | `vault_sec_enabled`, `vault_sec_biometric_enabled` | Security | `'true'/'false'` |
| Secure storage | `vault_sec_lock_mode` | Security | `'pin'` or `'pattern'` |
| Secure storage | `vault_sec_failed_attempts`, `vault_sec_lockout_until` | Security | Brute-force counter / epoch ms |

---

## 10. Notifications

File: `lib/core/notifications/notification_service.dart`

```dart
abstract class NotificationService {
  initialize(); requestPermissions();
  showInstantNotification({id, title, body, payload, channelId});
  scheduleNotification({id, title, body, scheduledDate, payload, channelId, matchDateTimeComponents});
  cancelNotification(id); cancelAllNotifications();
}
```

**Channels** (`NotificationChannels`):
| ID | Name | Used for |
|---|---|---|
| `daily_life_reminders` | Daily Life Reminders | Planner reminders, snoozes |
| `daily_life_countdowns` | Important Countdowns | Countdown day-of / 1-day / 7-day alerts |
| `daily_life_focus` | Pomodoro Focus Alerts | Pomodoro session end |

**Behavior rules in `scheduleNotification`:**
- If the date is in the past **and** it doesn't repeat, the notification is shown **immediately** instead.
- It uses `AndroidScheduleMode.exactAllowWhileIdle`.
- If scheduling throws (for example, no exact-alarm permission), it falls back to an instant notification.
- `matchDateTimeComponents`: `time` for daily/weekdays, `dayOfWeekAndTime` for weekly.
  Monthly has no match component, so it fires once.
- A notification tap only `debugPrint`s the payload. There is no deep-link handling yet.

**Notification ID scheme.** IDs are built in the UI as `string.hashCode & 0x7FFFFFFF`:
| Where | ID source |
|---|---|
| Quick reminder (Planner) | `'$title$today$timeStr'` |
| Full reminder sheet | `'$title$date$time$repeatType'` (DateTime/TimeOfDay `toString`) |
| Delete reminder | `'${title}${date}${startTime}'` |
| Countdown | `id.hashCode`, then `+1` (1 day before) and `+7` (7 days before) |
| Pomodoro end | instant notification on the focus channel |

⚠️ These formats don't all match (see [Known Issues](#18-known-issues--tech-debt)).

**Who calls notifications:** only `planner_page.dart`, directly through `sl<NotificationService>()`.
Blocs never touch notifications.

---

## 11. Feature Modules — Deep Dive

### 11.1 Today Hub

**Files:** `features/today_hub/…`

| Layer | Items |
|---|---|
| Entities | `HabitEntity` (`icon`, `color`, `description`, `category`, `scheduleType`, `repeatDays`, `reminderEnabled`, `reminderTime`, `isSkippedToday`, `completedDates`, `skippedDates`, `bestStreak`, `weeklyCompletionRate`, `monthlyCompletionRate`, `copyWith`), `TimelineItemEntity` (`copyWith`) |
| Use cases | `GetHabitsUseCase`, `ToggleHabitUseCase`, `AddHabitUseCase`, `UpdateHabitUseCase`, `DeleteHabitUseCase`, `SkipHabitUseCase`, `ToggleHabitDateUseCase`, `GetTodayTimelineUseCase`, `ToggleTimelineItemUseCase`, `AddTimelineItemUseCase`, `UpdateTimelineItemUseCase`, `DeleteTimelineItemUseCase` |
| Bloc events | `LoadTodayHub`, `ToggleHabit(id)`, `SkipHabit(id)`, `ToggleHabitDate(id, isoDate)`, `AddHabit(habit)`, `UpdateHabit(habit)`, `DeleteHabit(id)`, `SelectHabitCategory(category)`, `ToggleTimelineItem(id)`, `AddTimelineItem(item)`, `UpdateTimelineItem(item)`, `DeleteTimelineItem(id)` |
| State | `TodayHubLoaded{habits, timelineItems, selectedHabitCategory}` + `completedHabits`, `skippedHabits`, `longestActiveStreak`, `overallWeeklyConsistency`, `availableCategories`, `filteredHabits` getters |
| Sheets | `HabitEditorSheet`, `HabitDetailSheet`, `ManageHabitsSheet`, `TimelineEditorSheet`, `EveningWrapUpSheet` |

**Flow:**
```
TodayHubPage → sl<TodayHubBloc>()..add(LoadTodayHub)
  → getHabits() (merges db.habits + habit_details SQLite table, auto-resets isDoneToday across day boundaries) + getTodayTimeline()
  → TodayHubLoaded
Tap habit check circle → ToggleHabit(id) → flip isDoneToday, update completedDates & bestStreak, streak ±1
Tap habit row → HabitDetailSheet → 7-day interactive date toggles, 30-day heatmap, skip today, reminder toggle, edit, delete with confirmation
Tap Manage / Add → ManageHabitsSheet / HabitEditorSheet → full CRUD + local notification scheduling via NotificationService
Tap Evening Wrap-Up → EveningWrapUpSheet → review pending habits/tasks + save daily reflection to Notes DB
```

**UI pieces:** greeting header, compact audio-brief strip (`_AudioBriefSectionCard`: waveform tile · title + two-line summary · round play button; whole card plays the `AudioBriefingSheet` TTS brief),
`_MomentumSummaryCard` gradient hero (`AppDecorations.heroPrimaryGradient`: 64dp white progress ring, eyebrow + streak chip, motivation headline, one-line next task, frosted 3-metric strip for habits, tasks, and safe spend),
`SafeSpendMeterWidget` (dynamic snapshot via `GetDailySpendSnapshotUseCase`),
habit grouped card (`HabitBubbleWidget` compact 2–3 line rows: check indicator, squircle icon, title, one meta line `Category · Status · reminder`, optional single-line description, and a trailing streak pill stacked over 7-day dots; the header's tune and Add buttons are the only card actions),
section headers are plain 17px titles (no icon tiles) with trailing actions; `OsQuickLaunchDock` is four standalone tiles with no outer card; app-bar actions are borderless primary-tinted squircles;
timeline grouped card (`_TimelineUnifiedCard`: two-line `_TimelineRowTile` rows with check, icon, title, `time · category` meta line with an inline action chip that wraps only when needed, kebab for edit; inset dividers), and evening wrap-up card.
Standard 8pt/16pt/24pt grid rhythm: `AppSpacing.sm` top clearance, `gapH16` between hero cards, `gapH24` before section headers, `gapH8` between header and grouped card.

---

### 11.2 Planner (Reminders, Pomodoro, Countdowns)

**Files:** `features/planner/…`. `planner_page.dart` is about 2,600 lines.

#### Domain
- `PlannerItemEntity`: all DB columns plus computed getters:
  `icon, color, timeRange, dateDisplay ('Today'/'Tomorrow'/'Yesterday'/dd/MM), isRecurring,
  isOverdue (non-recurring, not done, before today), isToday, isUpcoming, parsedRepeatDays,
  recurrenceSummary ('Weekly (Mon, Wed)'), priorityColor, checklistDoneCount`
  and static `parseChecklistJson` / `serializeChecklist`.
- `ChecklistItem {id, title, isDone}` with toJson/fromJson.
- `CountdownItemEntity {id (String), title, date, category, colorValue, iconCodePoint, notes, remindAdvance}`.
- Repository: `getItemsForDate(isoDate)`, `addItem`, `updateItem`, `toggleItem(id, {targetDate})`,
  `deleteItem`, `clearCompletedItems`.
- Use cases: `GetPlannerItemsUseCase`, `AddPlannerItemUseCase`, `UpdatePlannerItemUseCase`,
  `TogglePlannerItemUseCase`, `DeletePlannerItemUseCase`, `ClearCompletedPlannerItemsUseCase`.

#### Data: how recurrence works (`planner_local_datasource.dart`)
`getItemsForDate(isoDate)`:
- `'all'` or empty → returns **every row** ordered by date and startTime (this is what the page loads).
- A specific date `D` → selects rows with `date <= D`, then in Dart:
  1. Skip if `endDate` exists and `D > endDate`.
  2. Check whether the item occurs on `D`:
     | repeatType | Occurs on D when |
     |---|---|
     | none | `date == D` |
     | daily | always |
     | weekdays | D is Mon–Fri |
     | weekly | D's weekday is in `repeatDays` (or the same weekday as the start date if `repeatDays` is empty) |
     | monthly | same day-of-month as the start date |
  3. `isDone` for that date: recurring → `D in completedDates`; non-recurring → `row.isDone`.

`toggleItem(id, targetDate)`:
- Recurring: adds or removes the date key in `completedDates`. The key is `targetDate`, or **today**
  when `targetDate` is `'all'`/null.
- Non-recurring: flips `isDone`.

`clearCompletedItems()`: deletes only **non-recurring** rows with `isDone = true`.

#### Bloc
- Events: `LoadPlanner(date)`, `AddPlannerItem{…}`, `UpdatePlannerItem{id,…}`,
  `TogglePlannerItem(id, {targetDate})`, `DeletePlannerItem(id)`, `ClearCompletedPlannerItems`.
- It remembers `_currentDate` (default `'all'`) and calls `_reload` after every mutation.
- `PlannerLoaded{items, date}` + `completedCount`.

#### Page: 3 tabs (`TabController(length: 3)`)
All three tabs constrain content inside centered `ConstrainedBox(maxWidth: 1080)` layouts and switch to balanced 2-column desktop studio grids on wide viewports (`>= 880–940px`).
1. **Reminders tab**
   - **Unified Theme-Adaptive Command Card (`PlannerHeroCard` + Embedded `PlannerWeekStrip`)**: Built on `AppDecorations.card(context)` + `context.palette` + Sunrise Amber (`AppColors.moduleTime` `#F59E0B`) top wash. Combines a `50×50` circular completion ring (`TweenAnimationBuilder`), data-driven status headline, optional 1-tap `'Up Next · <title>'` Focus Sprint pill (collapses when empty), `palette.surfaceMuted` 4-metric interactive filter strip (`Active`, `Today`, `Overdue`, `Done`), and hairline-divided Monday–Sunday `PlannerWeekStrip(embeddedInHero: true)` with week navigation (`<`, `>`), `"All Dates"` reset pill, and recurrence-aware status dots.
   - **3-Mode Segmented Workspace Switcher (`Agenda` · `Day Flow` · `Priority Matrix`)**: Uses `palette.surfaceMuted` + `palette.card` segmented pills and pairs side-by-side in a single `36px` row with the `All` / `Pending` / `Completed` status track on viewports `>= 580px`:
     - **Agenda (`PlannerViewMode.agenda`)**: Content-proportional `PlannerItemCard`s (`AppRadius.radiusMd`, `3.5px` left category/status spine, `AppColors.routineMorning`/`routineAfternoon`/`routineEvening` day-part pills, optional notes & inline checklist progress bar, compact `28px` footer actions, and 1-tap `Start Focus Sprint` bolt button).
     - **Day Flow (`PlannerTimelineView`)**: Chronological time-blocked vertical rail with category-tinted axis nodes, day-part distribution chips (`AM` / `PM` / `Eve` / `Flex`), content-adaptive block heights, and a live `NOW` horizontal indicator needle.
     - **Priority Matrix (`PlannerMatrixView`)**: Responsive 2×2 Eisenhower Matrix (`Do First · Urgent`, `Schedule · High`, `Focus Plan · Medium`, `Light / Later · Low`) using `AppColors.error` / `focusPomodoro` / `primary` / `success` and dynamic content sizing (empty quadrants collapse cleanly).
   - `SetReminderCard` & `SetReminderSheet.show(...)` (`maxWidth: 600`): inline date-targeted quick add + full modal composer with `Now`/`+1d`/`+7d` schedule presets, recurrence, priority, offset, checklist, and notes.
   - **1-Tap Task-to-Pomodoro Bridge** & **`PlannerSnoozeSheet`**: tapping `Start Focus Sprint` links the reminder (`_linkedTaskId`, `_linkedTask`, `_focusCategory`) and animates to **Pomodoro Focus**; tapping `Snooze +15m` opens `PlannerSnoozeSheet` (`15 Minutes`, `1 Hour`, `Tonight` / `In 3 Hours`, `Tomorrow Morning`).
2. **Focus (Pomodoro) tab**: persisted via **SharedPreferences** (`PomodoroSettingsEntity`, `FocusSessionEntity`, `FocusDistractionItem` in `pomodoro_entities.dart`):
   - Modes: Work 25 / Short break 5 / Long break 15 / Flowtime Stopwatch (`Flow ⏱`), customisable via `PomodoroCustomDurationSheet` (including rounds, daily goal, auto-start breaks/work, strict focus mode, and TTS voice coach cues).
   - **Theme-Adaptive Focus Studio (`PomodoroFocusCard`)**: Light/Dark adaptive `palette.card` surface (`AppRadius.radiusLg`) with mode-tinted top radial wash and precision 60-tick `_FocusDialPainter` (`AppColors.moduleTime` amber Deep Work, `AppColors.focusBreak` emerald Short Break, `AppColors.moduleNotes` sky Long Break, `AppColors.moduleVault` violet Flow Stopwatch), `+1m`/`+5m` quick boosts, Full-Screen `PomodoroZenScreen`, and live Planner subtask checklist toggling & task completion.
   - `PomodoroAnalyticsDashboard` provides a Daily Focus Goal ring, 7-day interactive Focus Trend bar chart, category distribution bar, Distraction Blocker ("Brain Dump") pad with 1-tap conversion to Planner tasks, manual session logger, and recent session history (rendered side-by-side in a 2-column Focus Studio on wide screens `>= 940px`).
3. **Countdowns tab**
   - List stored in **SharedPreferences** (`planner_saved_countdowns`), sorted chronologically (`upcoming` ascending by days remaining first, `past` milestones separated under `'Past Events'`).
   - **Theme-Adaptive Milestone Spotlight (`CountdownSpotlightCard`)**: Built on `AppDecorations.card(context)` + `context.palette` displaying `'Next Up · <title>'` with tabular `DAYS · HRS · MIN` digital tiles + `palette.surfaceMuted` 4-stat Milestone Overview (`Upcoming`, `Next 30d`, `Alerts On`, `Next In`).
   - `CountdownSheet` (`maxWidth: 580`): editorial modal composer with `+7d`/`+30d`/`+90d`/`+1y` target date presets → `_saveCountdowns` + `_syncCountdownNotifications` (9:00 AM on the day, 1 day before, 7 days before).
   - `CountdownCard`: `3.5px` left category accent spine, `AppRadius.radiusMd`, squircle category icon, urgency-tinted border for `Today`/`Tomorrow`, content-proportional 60-day proximity progress bar & hairline notes box, and 1-tap `Add to Planner`.

---

### 11.3 Money Manager

**Files:** `features/money/…`

| Layer | Items |
|---|---|
| Entities | `TransactionEntity` (`isExpense`, `formattedDate`), `BudgetEntity` (`daysRemaining`, `dailySafeSpend`), `SubscriptionEntity` (`renewalLabel`), `IouEntity` (`isLent`, `typeLabel`) |
| Use cases | `GetRecentTransactions`, `GetBudget`, `GetSubscriptions`, `GetIous`, `AddTransaction`, `UpdateBudget`, `ToggleAutoKill`, `SettleIou`, `AddIou` |
| Events | `LoadMoney`, `AddTransaction`, `UpdateBudget`, `ToggleAutoKill`, `SettleIou`, `AddIou` |
| State | `MoneyLoaded{transactions, budget, subscriptions, ious}` |

**Key formulas:**
```
totalSpent    = SUM(amount) of expense transactions since the 1st of this month
daysRemaining = lastDayOfMonth − today
dailySafeSpend = max(0, monthlyBudget − fixedBills − totalSpent) / max(1, daysRemaining)
```
- `getBudget()` auto-creates the budget row (40000 / 8000) if it's missing.
- `getRecentTransactions(limit: 30)` is ordered by date, newest first.
- `getIous()` returns **unsettled** only. `settleIou` sets `isSettled = true`.

**Page:** Shell hosts 4 tabs: *Overview · Activity · Budgets · Insights*.
All filters and temporal controls (`MonthSelectorChip`, `All time` filter chip, `PeriodSelectorBar`) are located directly in the body screen underneath the app bar rather than occupying the app bar actions. This keeps AppBars lightweight, spacious, and uncluttered, leaving actions dedicated solely to core modal utilities (Settings, Quick Capture, Budget Tips). Subviews and category filters scroll fluidly in responsive horizontal control strips.

---

### 11.4 Notes

**Files:** `features/notes/…`

| Layer | Items |
|---|---|
| Entity | `NoteEntity` (`tags: List<String>`, `color`, `previewContent`, `hasChecklist`, `checklistTotalCount`, `checklistDoneCount`, `checklistProgress`, `wordCount`, `copyWith`) |
| Use cases | `GetNotes`, `AddNote` (supports `isPinned`), `UpdateNote` (supports `isPinned`), `DeleteNote`, `TogglePinNote` |
| Events | `LoadNotes`, `AddNote`, `UpdateNote`, `DeleteNote`, `TogglePinNote` |
| State | `NotesLoaded(notes)` + `pinned` / `unpinned` getters (optimistic UI updates on `UpdateNote` & `TogglePinNote`) |
| Widgets | `NotesPage`, `NotesScratchpadCard`, `NoteCardWidget`, `NoteEditorSheet`, `NoteExpenseConverterSheet` |

- Notes are ordered **pinned first, then newest `updatedAt`** (with in-page sort cycling: `Recent` → `Title A–Z` → `Color`, plus smart filter pills for `All`, `Pinned`, `Checklists`, and `@tags`).
- **Layout:** Editorial 4-stat overview bar (`Total`, `Pinned`, `Lists`, `@Tags`), single-surface collapsible `NotesScratchpadCard` (auto-saved to `SharedPreferences` with cursor-preserving `Todo` / `Bullet` / `Time` tokens), responsive 2-column list on wide screens (`>= 820px`), and height-balanced 2/3-column Masonry grid mode.
- **Interactive Checklists:** Lines prefixed with `[ ] ` or `[x] ` render inside an inset progress block on `NoteCardWidget` and toggle inline via `UpdateNote` without opening the composer.
- **Cross-module actions:**
  - **Add to Planner (`+ Task`):** inserts directly into `db.plannerItems` (today, `09:00 AM`, category `'Notes'`).
  - **Add to Today's Timeline:** inserts directly into `db.timelineItems`.
  - **Convert to Expense (`Expense`):** opens `NoteExpenseConverterSheet` (auto-extracts amount & infers `MoneyCategory`, lets user pick category & `UPI`/`Card`/`Cash` mode) and logs via `AddTransactionUseCase`.
- `NoteEditorSheet` uses `BlocProvider.value` to pass the existing `NotesBloc` into the modal composer, supports direct pinning on create/edit, cursor-preserving formatting shortcuts, and custom `@tag` creation.

---

### 11.5 Vault

**Files:** `features/vault/…`

- Entities: `VaultPasswordEntity {id, title, username, category, iconCodePoint}`,
  `VaultDocumentEntity {id, title, category, expiry (display string), isExpiringSoon, hasReminder, iconCodePoint}`.
- ⚠️ `VaultLocalDataSourceImpl` returns **hardcoded lists** (HDFC NetBanking, Google Workspace,
  Wi-Fi; MacBook warranty, health insurance, motorcycle insurance). There is no DB table and no password storage.
- Bloc events: `LoadVault`, `ToggleDecoyMode`, `UnlockVault(isDecoy)`, `LockVault`.
  `VaultLoaded{passwords, documents, isDecoyMode, isUnlocked}`. `LoadVault` keeps the previous lock/decoy flags.
- Page has 2 tabs (passwords, documents).

**Lock flow (`vault_page.dart`):**
```
initState → _checkSecurity(): SecurityRepository.getConfig()
   security disabled → _isUnlocked = true (opt-in security)
   security enabled  → locked, shows VaultLockScreen
VaultLockScreen.onUnlocked(isDecoy) → VaultBloc.add(UnlockVault(isDecoy))
App paused/inactive (WidgetsBindingObserver) → auto-lock + LockVault
Header actions: decoy toggle, SecuritySettingsSheet, manual lock
No security yet → button opens SecuritySetupWizard → onCompleted → _checkSecurity()
```
The page keeps its own `_isUnlocked` flag **and** the Bloc has `isUnlocked`, so the state is duplicated.

---

### 11.6 Security (PIN / Pattern / Biometrics / Decoy)

**Files:** `features/security/…`. There is no Bloc; widgets receive a `SecurityRepository`.

- `SecurityConfigEntity {isSecurityEnabled, isBiometricEnabled, hasPin, hasPattern, hasDecoyPin,
  hasDecoyPattern, activeMode (pin|pattern)}` + `isConfigured`.
- `isSecurityEnabled` is true **only if** the flag is `'true'` **and** a PIN or pattern exists.

**Crypto & verification (`security_local_datasource.dart`):**
```
salt  = 32 random bytes (Random.secure), base64url, created once
hash  = sha256("$salt:$value")      value = PIN string, or pattern joined with '-'
verifyPin/Pattern:
   if lockout active → false
   if no stored hash → false        (no default PIN)
   match   → reset failed attempts
   mismatch→ failedAttempts++ ; at ≥5 → lockoutUntil = now + 30s
isDecoyPin/Pattern: match → reset attempts (no failure counting)
getLockoutUntil: once expired, clears both lockout and counter
authenticateBiometrics: availability check (500ms timeouts) → local_auth.authenticate → reset attempts on success
setPin/setPattern: also set enabled = true and lock mode
clearAllSecurity: deletes everything except the salt
```

**Widgets:**
| Widget | Role |
|---|---|
| `SecuritySetupWizard` | Multi-step bottom sheet: pick PIN/pattern → enter → confirm → optional decoy → biometrics |
| `VaultLockScreen` | Unlock UI; tries biometrics, real PIN/pattern, then decoy; shows lockout |
| `SecuritySettingsSheet` | Change PIN/pattern, set decoy, toggle biometrics, switch mode, disable/clear security |
| `PinDialpadWidget` | Numeric keypad |
| `PatternLockGridWidget` | 3×3 grid with a `CustomPainter`; emits a `List<int>` of dot indices |

Full design spec: `SECURITY_ARCHITECTURE.md`.

---

## 12. Shared Core Code

### `core/widgets/`

**`FeatureScaffold` (`feature_scaffold.dart`) is the standard shell for every top-level screen**
(Today, Planner, Money ×4, Notes, Vault). It provides the app bar (20px gutter, 20/700 title or 19/700 when subtitle is present,
68px height with subtitle, 56px standard, optional subtitle / leading / `titleTrailing` badge / actions / `bottom` tab bar, `onBack` →
back button with tooltip `'Back'`), page background, and a cross-fading
`FeatureStatus { loading, error, empty, content }` switch with default skeleton, error + retry
and empty views. `builder` only runs in the `content` state. Map Bloc state → status in the page
(e.g. `moneyFeatureStatus()` in `money_shell_scope.dart`). The same file also has
`FeatureStateView`, `FeatureLoadingView`, `FeatureErrorView`, `FeatureSectionHeader`,
`FeatureCard`, `FeatureHeaderButton` (accent pill: 36px height, radius 10) and `FeatureIconButton` (36×36 squircle, radius 10, customizable `backgroundColor` / `borderColor` for outlined or accent filled action buttons across Today, Notes, Planner, Vault, and Money).

| Widget | Purpose |
|---|---|
| `AppButton`, `AppTextField`, `SearchBarWidget`, `ChipInputWidget` | Basic inputs |
| `AppDropdownMenu` (`AppDropdownItem`, `AppDropdownDivider`) | Custom dropdown/popup menu |
| `AppActionSheet.show` (`AppActionItem`) | Generic action bottom sheet |
| `ConfirmationDialog.show` → `bool?` | Yes/no dialog |
| `FilterBottomSheet.show` | Filter UI |
| `AppLoader`, `InlineLoader`, `FullScreenLoader`, `AppShimmerLoader` | Loading states |
| `AppEmptyState`, `AppErrorWidget` | Empty and error states |
| `PaginatedListView` | Infinite-scroll list |
| `NetworkAwareWidget` | Online/offline wrapper (unused while there's no network) |
| `FloatingQuickBall` | Movable, minimizable 54×54 AssistiveTouch / Dynamic Island Quick Ball that morphs smoothly into the Quick-Capture capsule with zero lag (`ValueNotifier<Offset>` + `RepaintBoundary`) and zero pixel break (`ClipRRect` + `OverflowBox`) |
| `QuickCaptureSheet.show(mode)` | Zero-friction Voice / Quick Type / OCR Scan capture with smart NLP intent detection, editable parameters, and real DB persistence across Money, Planner, Today Habits, and Notes |
| `AudioBriefingSheet.show` | "Play my day" (UI only) |
| `HabitBubbleWidget`, `SafeSpendMeterWidget` | Today Hub building blocks (compact habit rows with a single meta line and stacked streak + 7-day dots; animated progress and budget breakdown toggle) |
| `ExpandableTextWidget` | Reusable multi-line text widget with smooth `AnimatedSize` "Show more / Show less" toggle for long titles, notes, and insights |

### `core/utils/`
`date_utils.dart`, `validators.dart`, `snackbar_utils.dart`.

### `core/constants/`
- `app_constants.dart`: timeouts, storage keys for a future auth system (JWT, onboarding), page size 10, retries.
- `string_constants.dart`: UI strings (`appName`, `holdToSpeak`, `quickType`, `scanText`, …).
- `asset_paths.dart`.

### `core/network/` (not used yet)
`ApiClient` (Dio), `ApiEndpoints`, `AuthInterceptor`, `ErrorInterceptor`, `LoggingInterceptor`,
`NetworkInfo`. Prepared for future cloud sync.

### `core/error/`
Exceptions: `ServerException`, `CacheException`, `NetworkException`, `ValidationException`.
Failures: `ServerFailure`, `CacheFailure`, `NetworkFailure`, `ValidationFailure`. Not wired into features.

---

## 13. Theme & Design System

`lib/config/theme/`:
- `app_colors.dart`: brand `primary #6366F1` (indigo), plus module colors:
  Time/Planner `#F59E0B` amber · Money `#10B981` emerald · Notes `#0EA5E9` sky · Vault `#8B5CF6` violet.
  Each has `Light`/`Dark` variants, and there's a full dark palette (`darkScaffoldBackground`, `darkCardBackground`, …).
- `app_text_styles.dart`, `app_spacing.dart`, `app_radius.dart`, `app_decorations.dart`
  (e.g. `floatingBar`), `app_theme.dart` (`lightTheme`, `darkTheme`).
- Font: **Inter**. Theme follows the system (light/dark).
- **Typography:** one scale in `app_text_styles.dart` (24 / 20 / 18 / 17 / 15 / 14 / 16-14-13 body /
  12 caption / 11 overline). `AppTextStyles.textTheme(brightness)` feeds both themes, so Material
  widgets render the same sizes in light and dark mode. The `AppTextStyles.*` constants carry
  light-mode colours; **new code should use `context.text.*`** and **`context.palette.*`**
  (`theme_context.dart`) instead of `isDark ? AppColors.darkX : AppColors.x` ternaries.
- Pages commonly check `Theme.of(context).brightness == Brightness.dark` and pass an `isDark` flag into widgets.
- **Layout conventions:**
  - Every page (Money included) uses a **20px horizontal gutter** (`AppSpacing.pageGutter`). AppBar
    `titleSpacing` = 20 and `actionsPadding` = 8 in both themes, so titles and the last action icon
    land on the gutter. A non-IconButton last action (e.g. `MonthSelectorChip`) needs `right: 12` padding.
  - Compact buttons that set `minimumSize: Size.zero` must also set
    `tapTargetSize: MaterialTapTargetSize.shrinkWrap`, or Material adds invisible 48px padding.
  - Borderless inline `TextField`s inside a styled container set `filled: false` (the dark theme fill
    otherwise draws a mismatched box).
  - Use `Text.rich`, not `RichText`: `RichText` ignores the theme and falls back to Roboto instead of Inter.
  - Segmented pills with long labels use `FittedBox(fit: BoxFit.scaleDown)` instead of ellipsis.
- Priority colors (in `PlannerItemEntity.priorityColor`): urgent red, high orange, medium indigo, low emerald.

---

## 14. Platform Configuration

**Android** (`android/app/src/main/AndroidManifest.xml`):
- Permissions: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`,
  `RECEIVE_BOOT_COMPLETED`, `VIBRATE`, `USE_BIOMETRIC`, `USE_FINGERPRINT`.
- Receivers: `ScheduledNotificationReceiver` and `ScheduledNotificationBootReceiver` (reschedule after reboot).
- `MainActivity : FlutterFragmentActivity` (required by `local_auth`).
- ⚠️ The Android package / applicationId is `com.dailylifeos.app`.

**iOS / macOS:** Darwin notification settings are set in code. The Face ID usage description
must be in `Info.plist` (see `SECURITY_ARCHITECTURE.md`).

**Web:** Drift needs `web/sqlite3.wasm` and `web/drift_worker.js`.

**Linux / Windows / macOS:** generated plugin registrants exist (they often show up as modified
files after `pub get`).

---

## 15. Testing

Run: `flutter test` · coverage: `flutter test --coverage` · lint: `flutter analyze --fatal-infos`

| File | Covers | ~Tests |
|---|---|---|
| `test/database_test.dart` | Schema, CRUD, seeder | 9 |
| `test/core/notifications/notification_service_test.dart` | Notification service | 6 |
| `test/core/notifications/fake_notification_service.dart` | **Test double**: records calls | — |
| `test/features/security/security_test.dart` | Hashing, lockout, decoy, config | 12 |
| `test/features/planner/data/datasources/planner_local_datasource_test.dart` | Recurrence, toggle | 3 |
| `test/features/planner/presentation/bloc/planner_bloc_test.dart` | Bloc flows | 2 |
| `test/features/planner/presentation/widgets/*_test.dart` | Card, sheets, pomodoro, countdown | 7 |
| `test/features/{money,notes,today_hub}/…datasource_test.dart` | Data sources | 1 each |
| `test/widget_test.dart` | App boots | 2 |
| `test/app_dropdown_menu_test.dart` | Dropdown widget | 1 |

**Typical test setup:**
```dart
final db = AppDatabase(NativeDatabase.memory());
await initDependencies(
  database: db,
  notificationService: FakeNotificationService(),
  secureStorage: mockStorage,      // mocktail
  localAuth: mockLocalAuth,
);
```

---

## 16. CI/CD

Plan doc: `cicd_pipeline_plan.md`.

**`.github/workflows/ci.yml`** runs on push or PR to `main`/`dev`. Steps:
1. Checkout, then set up Flutter 3.44.6 (cached), then `flutter doctor -v`
2. `flutter pub get`
3. `dart format --set-exit-if-changed .`  ← **unformatted code fails CI**
4. `flutter analyze --fatal-infos`  ← **even info-level lints fail CI**
5. `flutter test --coverage`, then upload `coverage/lcov.info` (kept 14 days)

Concurrency cancels older runs on the same ref.

**`.github/workflows/release.yml`** runs on a `v*` tag: CI checks, then **build Android** (Java 17, APK + AAB),
then create a GitHub Release with the artifacts.

```bash
git tag v1.0.0 && git push origin v1.0.0
```

**Before pushing, always run:**
```bash
dart format .
flutter analyze --fatal-infos
flutter test
```

---

## 17. Real vs. Mocked — Implementation Status

| Feature | Status |
|---|---|
| Habits toggle + streak | ✅ Real (DB) |
| Today timeline | ✅ Real (DB, seeded only; no UI to add items) |
| Safe-spend meter on Today | 🟡 Hardcoded numbers |
| Audio briefing / TTS | 🟡 UI only |
| Quick-Capture voice/type/scan | ✅ Real (NLP intent detection + editable Expense, Reminder, Habit, and Note DB persistence + View navigation) |
| Planner reminders CRUD + recurrence + checklist | ✅ Real (DB) |
| Planner notifications | ✅ Real (local notifications) |
| Snooze | 🟡 Schedules a notification; doesn't change the item |
| Pomodoro | ✅ Real (SharedPreferences settings, session log, 7-day chart, Zen mode, subtask sync, distraction pad) |
| Countdowns | ✅ Real (SharedPreferences + notifications) |
| Money: list, budget, subscriptions, IOUs | ✅ Real reads; toggle auto-kill / settle IOU are real |
| Money: add expense / add IOU / edit budget | 🔴 Bloc ready, **no UI wired** |
| Notes CRUD, pin, tags, scratchpad | ✅ Real |
| Note → planner task | ✅ Real (direct DB insert) |
| Vault passwords / documents | 🔴 Hardcoded mock data |
| Vault lock (PIN / pattern / biometric / decoy / lockout / auto-lock) | ✅ Real |
| Cloud sync / API | 🔴 Not started (Dio layer scaffolded) |
| Natural-language dates, OCR, location triggers, TTS reminders | 🔴 Not started (in PRD) |

---

## 18. Known Issues & Tech Debt

1. **Notification ID mismatch.** The full reminder sheet hashes `'$title$date$time$repeatType'`
   (with `DateTime`/`TimeOfDay` `toString()`), but delete hashes `'${title}${date}${startTime}'`.
   Deleting a reminder created from the full sheet probably **doesn't cancel** its notification.
   Fix idea: derive the notification ID from the DB `id`.
2. **Habits never reset daily.** `isDoneToday` stays true after midnight, and the streak isn't
   checked against `lastCompletedDate`.
3. **Blocs aren't shared across tabs.** Converting a note to a task, or adding a countdown to the
   planner, won't refresh other tabs until they reload. Today Hub's timeline doesn't read `PlannerItems` at all.
4. **Logic in the UI.** `planner_page.dart` (~2.6k lines) holds notification scheduling, Pomodoro
   and countdown persistence. Good candidates to move into use cases or a Cubit.
5. **Notes page writes to the DB directly** (`sl<AppDatabase>()`), bypassing clean architecture.
6. **Unused abstractions:** `UseCase`/`Either`/`Failure`, `core/network`, `HomePage`, auth keys in `AppConstants`.
7. **Missing try/catch** in most Bloc mutation handlers, so a DB error there is unhandled.
8. **Monthly recurrence** doesn't handle day 29–31 in short months, and monthly notifications fire only once.
9. **Duplicate lock state** in Vault (page `_isUnlocked` + Bloc `isUnlocked`).
10. **`.env` is bundled as an asset.** Never put real secrets in it.
11. **Android package** is `com.dailylifeos.app` (renamed from the template `com.example.fine_route`).
12. Equatable `props` on some events/entities are incomplete (e.g. `AddPlannerItem`, `HabitEntity`),
    so two different objects can compare equal.

---

## 19. How-To Recipes

### Add a new feature module
1. Create `lib/features/<name>/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{bloc,pages,widgets}}`.
2. If it needs persistence, add a Drift table in `app_database.dart`, add it to `@DriftDatabase(tables: …)`,
   bump `schemaVersion`, add a migration step, and run build_runner.
3. Write Entity → Repository (abstract) → UseCases → Model → LocalDataSource → RepositoryImpl.
4. Write Event/State/Bloc (export event and state from the bloc file).
5. Register everything in `injection_container.dart` (lazy singletons + `registerFactory` for the Bloc).
6. Page: `BlocProvider(create: (_) => sl<XBloc>()..add(const LoadX()), child: _XView())`.
7. Add it to `MainNavigationShell._pages` or open it as a sheet.
8. Add tests using `AppDatabase(NativeDatabase.memory())`.

### Add a column to an existing table
```dart
// 1. app_database.dart
TextColumn get myField => text().withDefault(const Constant(''))();
// 2. schemaVersion => 3;
// 3. onUpgrade: if (from < 3) { await m.addColumn(table, table.myField); }
```
```bash
dart run build_runner build --delete-conflicting-outputs
```
Then update the Model's `fromDrift`, the Entity, the data source insert/update, and the tests.

### Schedule a notification
```dart
await sl<NotificationService>().scheduleNotification(
  id: someStableId & 0x7FFFFFFF,
  title: 'Reminder: …', body: '…',
  scheduledDate: dateTime,
  channelId: NotificationChannels.reminders,
  matchDateTimeComponents: DateTimeComponents.time, // daily repeat (optional)
);
```
In tests, inject `FakeNotificationService`.

### Common commands
```bash
flutter pub get
flutter run
dart run build_runner build --delete-conflicting-outputs
dart format .
flutter analyze --fatal-infos
flutter test --coverage
```

---

## 20. Glossary

| Term | Meaning |
|---|---|
| **sl** | Global `GetIt` service locator |
| **Entity / Model** | Entity = domain object; Model = Entity subclass with DB/JSON mapping |
| **Companion** | Drift-generated insert/update object (`PlannerItemsCompanion`) |
| **Value / Value.absent()** | Drift wrapper: set a column / leave it unchanged |
| **completedDates** | Per-day completion list for recurring planner items |
| **repeatDays** | ISO weekdays `1=Mon … 7=Sun`, comma-separated |
| **Safe spend** | Money left per day for the rest of the month |
| **Auto-kill** | Subscription flag meant to auto-cancel before renewal (not yet active) |
| **IOU** | Money lent to or borrowed from a person |
| **Decoy PIN/pattern** | Second credential that opens the vault in "decoy mode" (fake content) for coercion scenarios |
| **Lockout** | 30s block after 5 wrong PIN/pattern attempts |
| **Quick-Capture** | Floating bar for voice/type/scan input |

---

## 21. Other Docs in the Repo

| File | Content |
|---|---|
| `README.md` | Setup, run, CI badges |
| `daily_life_os_product_requirements_document.md` | Full PRD: vision, modules, future features |
| `SECURITY_ARCHITECTURE.md` | Vault security design, native setup, unlock decision flow |
| `sqlite_plan.md` | Original Drift integration plan |
| `cicd_pipeline_plan.md` | CI/CD design and GitHub secrets setup |
| `PROJECT_KNOWLEDGE.md` | **This file** |

> ✏️ **Keep this file updated** when you add a feature, change the schema, or fix an item in
> [Known Issues](#18-known-issues--tech-debt).
