# 📘 Daily Life OS — Project Knowledge Base

> **Purpose of this file:** a single place where any developer (or AI assistant) can learn
> how this project is built, how data flows, where things live, and what is real vs. mocked.
> Read this before touching the code.
>
> _Last updated: 2026-11-14 (branch `V_1.0.1`)_

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
    - [Profile & Preferences](#117-profile--preferences)
    - [Quick Capture](#118-quick-capture)
    - [Command Palette (Spotlight Search)](#119-command-palette-spotlight-search)
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
| ⚡ Input | **Quick Capture** | Floating ball: type / voice / scan text → expense, reminder, habit or note |
| 🔎 Search | **Command Palette** | Spotlight-style search across every module |
| 👤 You | **Profile** | Name, avatar, theme mode, currency, which Today cards are shown |

**Design principles** (from the PRD): offline-first, input in under 3 seconds (voice/type/scan),
modules that talk to each other, and privacy.

**Current reality:** 100% offline. There is **no backend**. All data is on the device.

---

## 2. Tech Stack

| Concern | Package | Notes |
|---|---|---|
| Language / SDK | Dart `^3.12.2`, Flutter `3.44.6` stable | Version pinned in CI |
| State management | `flutter_bloc ^9.1.1` | One Bloc per feature (10 Blocs, Security included) |
| Dependency injection | `get_it ^9.2.1` | Global locator `sl` |
| Routing | `go_router ^14.2.7` | Only one route right now |
| Local DB | `drift ^2.21.0` + `drift_flutter` | SQLite; codegen via `build_runner` |
| Key-value storage | `shared_preferences` | Profile, countdowns, Pomodoro, notes scratchpad, vault item metadata, quick-ball position |
| Secure storage | `flutter_secure_storage` | PIN/pattern hashes, security flags, user-added vault secrets |
| Biometrics | `local_auth ^3.0.2` | Fingerprint / Face ID |
| Hashing | `crypto` | SHA-256 + salt |
| Notifications | `flutter_local_notifications ^22.3.2` + `timezone` | Scheduled and instant |
| Env config | `flutter_dotenv` | `.env` keys: `API_BASE_URL`, `APP_ENV`, `APP_NAME` |
| Networking (unused) | `dio` | Ready but not used by any feature |
| Functional types | `dartz`, `equatable` | `equatable` everywhere; `dartz` `Either` only in Profile, Quick Capture, Command Palette and Security |
| Charts | `fl_chart ^1.3.0` | Money charts (balance trend, cashflow, category breakdown, spend summary) |
| Text-to-speech | `flutter_tts` (+ `web`) | Audio briefing, via `core/services/tts` (conditional io / web / stub import) |
| Misc | `intl`, `image_picker`, `permission_handler`, `path_provider` | `image_picker` is used for the profile avatar |
| Testing | `flutter_test`, `integration_test`, `bloc_test`, `mocktail` | |
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
│   ├── bloc/                         # BlocStatus, BlocEffectMixin, AppBlocObserver
│   ├── constants/                    # app_constants, string_constants, asset_paths
│   ├── database/
│   │   ├── app_database.dart         # Drift tables + DB class (schema v4)
│   │   ├── app_database.g.dart       # GENERATED — never edit by hand
│   │   └── database_seeder.dart      # Demo data on first launch + Money defaults
│   ├── error/                        # exceptions, failures, failure_mapper (guardRepositoryCall)
│   ├── monitoring/app_monitor.dart   # Error capture, redaction, breadcrumbs, friendly messages
│   ├── network/                      # Dio ApiClient + interceptors (UNUSED today)
│   ├── notifications/notification_service.dart
│   ├── services/tts/                 # AppTtsService (io / web / stub)
│   ├── usecase/usecase.dart          # Base UseCase<T, Params> (used by the newer features)
│   ├── utils/                        # currency_utils, date_utils, validators, snackbar_utils
│   └── widgets/                      # Reusable UI (FeatureScaffold, AppText, buttons, sheets, loaders…)
├── di/injection_container.dart       # get_it registrations
└── features/
    ├── navigation/      # MainNavigationShell + NavigationBloc + OsQuickLaunchDock
    ├── home/            # HomePage — LEGACY, not referenced anywhere
    ├── today_hub/       { data, domain, presentation }
    ├── planner/         { data, domain, presentation(+widgets) }
    ├── money/           { data, domain, presentation }   # largest feature (~17k lines)
    ├── notes/           { data, domain, presentation }
    ├── vault/           { data, domain, presentation }
    ├── security/        { data, domain, presentation(bloc + widgets) }
    ├── profile/         { data, domain, presentation(bloc + widgets) }
    ├── quick_capture/   { data, domain(+services), presentation(bloc + widgets) }
    └── command_palette/ { data, domain, presentation(bloc + widgets) }

test/                                 # mirrors lib/, plus device/, performance/, security/, integration/
integration_test/                     # app_production_test.dart
store_assets/                         # App Store / Play Store screenshots
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

There are **two generations of feature code**. Follow the style of the feature you are editing.

| | Older style | Newer style |
|---|---|---|
| Features | Today Hub, Planner, Money, Notes, Vault | Profile, Quick Capture, Command Palette, Security (lock flow) |
| Use case return | plain `Future<T>` | `Future<Either<Failure, T>>` (`dartz`) |
| Error handling | `try/catch` in the Bloc | Repository wraps calls in `guardRepositoryCall` (`core/error/failure_mapper.dart`); Bloc does `result.fold` |
| State | `XInitial → XLoading → XLoaded \| XError` classes | One `copyWith` state with a `BlocStatus` field (`core/bloc/bloc_status.dart`) |
| One-shot UI actions | Read from state | `BlocEffectMixin` + `BlocEffectListener` (Security, Quick Capture) |

Error handling in the older Blocs, feature by feature:
- **Today Hub, Notes:** every handler has `try/catch`.
- **Money:** mutations go through `_mutate`, which catches and puts the message in
  `MoneyLoaded.actionError` (the shell shows it as a snackbar).
- **Planner:** only `LoadPlanner` is guarded. Mutation handlers have **no try/catch**.
- Uncaught Bloc errors reach `AppBlocObserver` → `AppMonitor`, which shows a user-friendly banner.

Other conventions:
- **Reload after mutate:** after a write, the Bloc re-fetches and emits a new state. Notes
  (`UpdateNote`, `TogglePinNote`) and Planner (`TogglePlannerItem`) emit an optimistic state first.
- **Bloc files** re-export their event/state files (`export 'x_event.dart';`), so importing the
  bloc file gives you everything.
- **Feature Blocs are `registerFactory`.** Each page creates its own Bloc instance. Blocs are **not
  shared across tabs**. `ProfileBloc` is the one exception: a lazy singleton shared app-wide.
- **Cross-tab refresh after quick capture:** `NavigationBloc` bumps `captureRefreshGeneration`,
  which changes the `ValueKey` of the Today, Planner, Money and Notes pages so they rebuild with a
  fresh Bloc. Other cross-module writes (e.g. note → planner task) do not trigger this.
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
 ├─ AppMonitor.instance.installGlobalErrorHandlers() + attachFrameTimingObserver()
 ├─ Bloc.observer = AppBlocObserver()
 ├─ dotenv.load('.env')                         (errors ignored)
 ├─ await initDependencies()                    (traced; also preloads the saved profile)
 ├─ await DatabaseSeeder.seedIfEmpty(db)        (traced; demo data if habits is empty, else Money defaults)
 ├─ NotificationService.initialize()            (NOT awaited; errors go to AppMonitor)
 └─ runApp(const DailyLifeOSApp())
        └─ BlocBuilder<ProfileBloc> → MaterialApp.router
             theme: AppTheme.lightTheme / darkTheme
             themeMode: from profile ('system' | 'light' | 'dark')
             builder: AppMonitorUserErrorHost    (global error banner)
             route "/" → MainNavigationShell
```

- `initDependencies` and seeding are awaited without a `try/catch`; only `.env` loading and
  notification init tolerate failure.
- `DailyLifeOSApp` is a `StatefulWidget` that creates the `GoRouter` once, so theme or currency
  changes never reset navigation. It takes no `router` parameter.
- The app rebuilds only when `themeMode` or `currencyCode` changes; the builder also calls
  `CurrencyUtils.setCurrency(...)`.
- If `ProfileBloc` is not registered, it falls back to a plain `MaterialApp.router` with the system theme.

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
- Registration order: Core services → Database → DataSources → Repositories → UseCases → Blocs →
  profile preload → `ProfileBloc`.

| Type | Lifetime |
|---|---|
| `AppMonitor`, `FlutterSecureStorage`, `NotificationService`, `AppDatabase` | Lazy singleton |
| All `*LocalDataSource`, `*Repository`, `*UseCase`, `QuickCaptureIntentParser` | Lazy singleton |
| `TodayHubBloc`, `PlannerBloc`, `MoneyBloc`, `NotesBloc`, `VaultBloc`, `NavigationBloc`, `QuickCaptureBloc`, `CommandPaletteBloc` | **Factory** (new per page / sheet) |
| `ProfileBloc` | **Lazy singleton**, created with the preloaded profile and an immediate `LoadProfile` |
| `SecurityBloc` | Not registered; `VaultLockScreen` builds it with `SecurityBloc.fromRepository(repo)` |

- The saved profile is read **before** `ProfileBloc` is registered, so the first frame already
  uses the saved theme mode.
- `TodayHubBloc` receives `NotificationService` (habit reminders). `NotifyBudgetThresholdUseCase`
  and `QuickCaptureLocalDataSourceImpl` receive it too.
- `CommandPaletteLocalDataSourceImpl` is built from the other features' **use cases**, not the DB.
- UI code still calls `sl<NotificationService>()` directly (Planner page, Money tools sheets) and,
  in Notes, `sl<AppDatabase>()`.

---

## 7. Navigation & Screen Layout

- `config/routes/app_router.dart`: a single `GoRoute('/')` → `MainNavigationShell`.
  Sheets and dialogs use `showModalBottomSheet` / `Navigator.pop`, not go_router.
- `features/navigation/presentation/pages/main_navigation_shell.dart` is driven by
  **`NavigationBloc`** (`NavigationState{currentIndex, previousNonMoneyIndex, captureRefreshGeneration}`;
  events `SelectNavigationTab`, `ExitMoneyNavigationMode`, `RefreshCapturedModules`). Tab metadata
  (label, icons, accent color) lives in `NavigationTabEntity.tabs`.
  - `IndexedStack` holding 5 pages. **Today is built at startup; the other tabs are built on
    first visit** (a `SizedBox.shrink()` placeholder until then) and then kept alive:

    | Index | Tab | Page | Accent color |
    |---|---|---|---|
    | 0 | Today | `TodayHubPage` | `AppColors.primary` (indigo) |
    | 1 | Planner | `PlannerPage` | `moduleTime` (amber) |
    | 2 | Money | `MoneyManagerPage` | `moduleMoney` (emerald) |
    | 3 | Notes | `NotesPage` | `moduleNotes` (sky) |
    | 4 | Vault | `VaultPage` | `moduleVault` (violet) |

  - **Money mode:** while the Money tab is selected (`isInMoneyMode`), the main bottom bar and the
    quick ball are hidden. Money shows its own bottom bar (`MoneyBottomNavBar`); leaving Money
    (`ExitMoneyNavigationMode`) returns to the previously selected tab.
  - **Refresh after capture:** closing the quick-capture sheet dispatches `RefreshCapturedModules`,
    which re-keys the Today, Planner, Money and Notes pages (Vault is not re-keyed). A "View"
    snackbar action jumps to the tab the capture was saved in.
  - **Movable, Minimizable Floating Quick-Capture Ball (`FloatingQuickBall`,
    `features/quick_capture/presentation/widgets/`)**: persists its position in `SharedPreferences`
    and morphs between a 54×54 ball and the expanded capsule (`Hold to Speak`, `Quick Type`, `Scan`,
    a Spotlight button that opens the Command Palette, and `Minimize`). It can be turned off in
    Profile (`showFloatingQuickBall`). See [Quick Capture](#118-quick-capture).

---

## 8. Database (Drift / SQLite)

File: `lib/core/database/app_database.dart` · DB name: `daily_life_os` · **schemaVersion = 4** ·
10 Drift tables + 1 raw-SQL table (`habit_details`)

On web, Drift uses `sqlite3.wasm` + `drift_worker.js` from `web/`.

### Tables

#### `Habits`
| Column | Type | Notes |
|---|---|---|
| id | int PK auto | |
| title | text | |
| iconCodePoint, colorValue | int | |
| streakDays | int (0) | +1 on check, −1 on uncheck |
| isDoneToday | bool (false) | Reset to false by `getHabits()` when `lastCompletedDate` is not today |
| lastCompletedDate | text? | ISO date |
| createdAt | text | |

#### `habit_details` (raw SQL, **not a Drift table**)
Created with `CREATE TABLE IF NOT EXISTS` by `TodayHubLocalDataSourceImpl._ensureDetailsTable()`
and read/written with `customSelect` / `customStatement`. It is not in `@DriftDatabase(tables: …)`,
so Drift migrations and `_ensureSchemaIntegrity` do not know about it.

`habit_id (PK), description, category ('Morning'), schedule_type ('daily'), repeat_days ('1,2,3,4,5,6,7'),
reminder_enabled, reminder_time, completed_dates (CSV ISO dates), skipped_dates (CSV), best_streak`

#### `TimelineItems` (Today Hub feed — separate from the planner)
`id, time (text, e.g. '09:00 AM'), title, category, colorValue, iconCodePoint, isDone, action (text label for the action button), date (ISO date)`

#### `Transactions`
`id, title, category, amount (real), mode ('UPI'|'Card'|'Cash'), iconCodePoint, date (full ISO timestamp), type ('expense'|'income', default 'expense'), note (text?, v3)`

#### `BudgetSettings` (single row, id = 1)
`id (PK, default 1), monthlyBudget (default 40000), fixedBills (default 8000), currencyCode ('INR', v3), budgetAlertsEnabled (true, v3), moneyLockEnabled (false, v3)`

#### `CategoryBudgets` *(v3)*
`id, category (unique `MoneyCategory` key, e.g. 'food'), monthlyLimit (default 0 = no limit)`

#### `MoneyAccounts` *(v3)*
`id, name, type ('cash'|'savings'|'investment'), balance (default 0), colorValue, iconCodePoint`

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
onCreate:   m.createAll()
onUpgrade:  _ensureSchemaIntegrity(m)
beforeOpen: if (!details.wasCreated) _ensureSchemaIntegrity(createMigrator())
```
There are **no `if (from < N)` blocks**. `_ensureSchemaIntegrity` is idempotent: it reads
`sqlite_master` and `PRAGMA table_info`, creates every Drift table that is missing and adds every
column that is missing. It runs on upgrade **and on every open** of an existing database, so an
interrupted migration repairs itself. Errors from `createTable` / `addColumn` are swallowed.

**When you change a table:** bump `schemaVersion`, then run
`dart run build_runner build --delete-conflicting-outputs` to regenerate `app_database.g.dart`.
New tables and new columns need no migration code. Give a new column a default or make it nullable
(SQLite cannot add a NOT NULL column without one). Renames, type changes, drops and data
back-fills are **not** handled; those need explicit code in `onUpgrade`.

### Seeder (`database_seeder.dart`)
`seedIfEmpty` checks the `habits` table:
- **Empty (first launch):** inserts demo data:
  - Habits: *Drink 3L Water, Daily Vitamins, Read 15 mins, Meditation (10m)*
  - Timeline (today): four items, e.g. *Morning Standup & Deep Focus, Electricity Bill Due (₹450)*
  - Transactions: three for today plus a multi-day history (*Salary Credit, Monthly Rent, …*)
  - Subscriptions (*Netflix 4K, Spotify, GitHub Copilot*), IOUs (*David Kumar, Priya Sen*)
  - Notes, Planner (*Morning Standup, Gym Workout*)
- **Always (also on later launches):** `_ensureMoneyDefaults` creates the budget-settings row, the
  category-budget rows and default accounts (*Wallet Cash, Savings Account, Mutual Funds*) if missing.
- `clearMoneyDemoDataOnce` (wipes Money demo rows once, flag `money_started_fresh_v2`) exists but
  is **not called anywhere**.

---

## 9. Other Storage (SharedPreferences & Secure Storage)

| Store | Key | Owner | Content |
|---|---|---|---|
| SharedPreferences | `planner_saved_countdowns` | `planner_page.dart` | JSON list of `CountdownItemModel` |
| SharedPreferences | `planner_pomodoro_settings_v2`, `planner_pomodoro_sessions_v2`, `planner_pomodoro_distractions_v2` | Planner (Pomodoro) | Settings, session log, distraction pad |
| SharedPreferences | `daily_scratchpad_content` | `notes_page.dart` | Scratchpad text |
| SharedPreferences | `os_profile_*` (name, tagline, avatar path, avatar preset) and `os_pref_*` (quick ball, quick-launch dock, audio-brief card, safe-spend card, evening wrap-up card, auto-play briefing, haptics, theme mode, currency code, daily focus goal) | `profile_local_datasource.dart` | User profile and app preferences |
| SharedPreferences | `quick_ball_x_ratio_v1`, `quick_ball_y_ratio_v1` | `floating_quick_ball.dart` | Quick-ball position |
| SharedPreferences | `vault_custom_passwords_v1`, `vault_custom_documents_v1`, `vault_deleted_password_ids_v1`, `vault_deleted_document_ids_v1` | `vault_page.dart` | User-added vault items (**metadata only**) and hidden item ids |
| Secure storage | `vault_secure_custom_secrets_v2` | `vault_page.dart` | JSON map `id → password` for user-added vault entries (migrated from the old plaintext prefs key `vault_custom_secrets_v1`, which is then removed) |
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
| Snooze | `(item.id.hashCode + minutes)` |
| Pomodoro end | instant notification on the focus channel |
| Habit reminder | `habitId + 500000` (`TodayHubBloc.habitNotificationId`) |
| Quick-capture reminder | `Object.hash(title, notifyAt)` |
| Budget threshold alert | `7300 + category index` |
| IOU due reminder / nudge | `person.hashCode.abs() % 90000 + 10000` / `iou.id + 40000` |

⚠️ These formats don't all match (see [Known Issues](#18-known-issues--tech-debt)).

**Who calls notifications:**
| Caller | How |
|---|---|
| `planner_page.dart` | Directly via `sl<NotificationService>()` (reminders, snooze, countdowns, Pomodoro) |
| `TodayHubBloc` | Injected service; schedules/cancels habit reminders on add, update and delete |
| `NotifyBudgetThresholdUseCase` (Money) | Instant alert when a category crosses the near-limit threshold or goes over budget, if `budgetAlertsEnabled` |
| `money_tools_sheets.dart` | Directly via `sl`; IOU due-date reminder and "remind now" |
| `QuickCaptureLocalDataSourceImpl` | Injected service; schedules a notification for a captured reminder |

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

**Files:** `features/planner/…`. `planner_page.dart` is about 3,900 lines.

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
  `TogglePlannerItem` first emits an optimistic list with `isDone` flipped, then reloads.
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

The largest feature: 49 files, about 17k lines.

| Layer | Items |
|---|---|
| Entities | `TransactionEntity`, `BudgetEntity` (`daysRemaining`, `dailySafeSpend`), `SubscriptionEntity`, `IouEntity`, `MoneyCategory`, `CategoryBudgetEntity` (+ `BudgetStatus { onTrack, nearLimit, overBudget, noLimit }`), `MoneyAccountEntity` / `MoneyAccountType`, `MoneySettingsEntity {currencyCode, budgetAlertsEnabled, moneyLockEnabled}`, `MoneyInsights` (+ `MoneyPeriod { weekly, monthly, sixMonths, yearly }`, `CategorySpend`, `MonthlyValue`, `AiFinancialInsight`) |
| Use cases (repository) | Transactions: `GetRecent`, `GetAll`, `GetInRange`, `Add`, `Update`, `Delete` · Budget: `GetBudget`, `UpdateBudget`, `GetCategoryLimits`, `SetCategoryLimit` · Accounts: `Get`, `Add`, `Update`, `Delete` · Subscriptions: `Get`, `Add`, `Update`, `Delete`, `ToggleAutoKill` · IOUs: `Get`, `Add`, `Settle`, `Delete` · Settings: `GetMoneySettings`, `UpdateMoneySettings` · `GetDailySpendSnapshotUseCase` (used by Today Hub and the audio briefing) |
| Use cases (pure / service) | `FilterMonthTransactions`, `FilterPeriodTransactions`, `BuildCategoryBudgets`, `ComputeMoneyInsights` (`money_insights_usecase.dart`), `NotifyBudgetThresholdUseCase` |
| Events | `LoadMoney`, `ChangeMonth`, `ChangeMoneyPeriod`, `AddTransaction`, `UpdateTransaction`, `DeleteTransaction`, `UpdateBudget`, `ApplyBudgetPlan`, `SetCategoryLimit`, `AddAccount`, `UpdateAccount`, `DeleteAccount`, `TransferBetweenAccounts`, `AddSubscription`, `DeleteSubscription`, `ToggleAutoKill`, `RecordSubscriptionPayment`, `AddIou`, `SettleIou`, `DeleteIou`, `UpdateMoneySettings`, `ResetAllMoneyData` |
| State | `MoneyLoaded{transactions, allTransactions, monthTransactions, periodTransactions, budget, subscriptions, ious, selectedMonth, selectedPeriod, categoryBudgets, categoryLimits, accounts, insights, settings, actionError}` + `subscriptionsTotal`, `totalLent`, `totalBorrowed` |

Mutations run through `MoneyBloc._mutate`: run the action, on failure set `actionError` (snackbar),
on success reload, then fire budget-threshold notifications when asked and alerts are enabled.

**Key formulas:**
```
totalSpent    = SUM(amount) of expense transactions since the 1st of this month
daysRemaining = lastDayOfMonth − today
dailySafeSpend = max(0, monthlyBudget − fixedBills − totalSpent) / max(1, daysRemaining)
```
- `getBudget()` auto-creates the budget row (40000 / 8000) if it's missing.
- `getRecentTransactions(limit: 30)` is ordered by date, newest first.
- `getIous()` returns **unsettled** only. `settleIou` sets `isSettled = true`.

**Page:** `MoneyManagerPage` → `MoneyShellPage`, which hosts 4 lazily built tabs
(*Overview · Activity · Budgets · Insights*, indexes in `MoneyTab`) and its own `MoneyBottomNavBar`
with a centre **Add** action that opens `AddTransactionSheet`. `MoneyShellScope` (InheritedWidget)
gives child pages `exitMoney` and `selectTab`. System back goes to Overview first, then leaves Money.

- **Money lock:** when `settings.moneyLockEnabled` is on, the shell shows `VaultLockScreen` (the same
  PIN / pattern / biometric flow as the Vault) before any Money content.
- **Tool sheets** (`money_tools_sheets.dart`): `SubscriptionsSheet`, `IouSheet`, `MoneyAccountsSheet`,
  `MoneySettingsSheet`. Other sheets: `AccountTransferSheet`, `BillSplitSheet`, `EditLimitSheet`,
  `MoneyReportSheet`, `MonthPickerSheet`.
- **Currency:** all amounts format through `CurrencyUtils` (`core/utils/currency_utils.dart`;
  INR, USD, EUR, GBP, AED, JPY). The active currency is set from the **profile** in `main.dart`.
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
- ⚠️ `VaultLocalDataSourceImpl` still returns **hardcoded lists** (HDFC NetBanking, Google Workspace,
  Wi-Fi; MacBook warranty, health insurance, motorcycle insurance). There is no DB table.
- **User-added items live in the page, not the data layer.** `vault_page.dart` (~2,700 lines) keeps
  its own lists of custom passwords and documents, persists their metadata as JSON in
  SharedPreferences and the password values in secure storage (see [section 9](#9-other-storage-sharedpreferences--secure-storage)),
  and merges them over the hardcoded base lists (`_mergedPasswords` / `_mergedDocuments`). Deleting a
  base item only records its id in a "deleted ids" list. The page also has search, category filters,
  a password generator (`Random.secure`) and a clipboard auto-clear timer.
- Bloc events: `LoadVault`, `ToggleDecoyMode`, `UnlockVault(isDecoy)`, `LockVault`.
  `VaultLoaded{passwords, documents, isDecoyMode, isUnlocked}`. `LoadVault` keeps the previous lock/decoy flags.
  Load errors go to `AppMonitor` and surface as `AppMonitor.friendlyMessage(...)`.
- Page has 2 tabs (passwords, documents).

**Lock flow (`vault_page.dart`):**
```
initState → _checkSecurity(): SecurityRepository.getConfig()
   security disabled → _isUnlocked = true (opt-in security)
   security enabled  → locked, shows VaultLockScreen
VaultLockScreen.onUnlock(isDecoy) → VaultBloc.add(UnlockVault(isDecoy))
App paused/inactive (WidgetsBindingObserver) → auto-lock + SecurityRepository.lockSession() + LockVault
Header actions: decoy toggle, SecuritySettingsSheet, manual lock
No security yet → button opens SecuritySetupWizard → onCompleted → _checkSecurity()
```
The page keeps its own `_isUnlocked` flag **and** the Bloc has `isUnlocked`, so the state is duplicated.

---

### 11.6 Security (PIN / Pattern / Biometrics / Decoy)

**Files:** `features/security/…`. Widgets receive a `SecurityRepository`. The **unlock flow** runs
through `SecurityBloc`; the setup wizard and settings sheet still call the repository directly.

- `SecurityPolicy`: `maxFailedAttempts = 5`, `lockoutDuration = 30s`, `pinLength = 4`.
- **`SecurityBloc`** (not in `sl`; `VaultLockScreen` creates it with `SecurityBloc.fromRepository`):
  events `LoadSecurityStatus`, `SwitchSecurityLockMode`, `PinInputChanged` (auto-verifies at 4 digits),
  `PatternInputStarted`, `PatternSubmitted`, `BiometricUnlockRequested`, `SecurityLockoutTicked`
  (1-second countdown). State is one `SecurityState{status, config, currentMode, biometricsAvailable,
  enteredPin, errorMessage, lockoutSeconds, isVerifying}`. One-shot effects: `SecurityUnlocked(isDecoy)`
  and `SecurityAttemptRejected`.
- Use cases (`security_usecases.dart`, all `Either<Failure, T>`): `LoadSecurityLockStatusUseCase`,
  `VerifySecurityPinUseCase`, `VerifySecurityPatternUseCase` (both return `UnlockAttemptResult`),
  `AuthenticateBiometricsUseCase`.
- **Master session flag:** the data source keeps an in-memory `isMasterSessionUnlocked`;
  `lockSession()` clears it. The Command Palette hides Vault results while security is enabled and
  the session is locked.
- Hash comparison uses a constant-time compare (`constantTimeEquals`).
- `VaultLockScreen` is reused by the Money module when the Money lock is on.

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

### 11.7 Profile & Preferences

**Files:** `features/profile/…` · storage: SharedPreferences only (no DB table).

- `UserProfileEntity {displayName, tagline, avatarPath, avatarPresetIndex, showFloatingQuickBall,
  showQuickLaunchDock, showAudioBriefCard, showSafeSpendCard, showEveningWrapUpCard,
  autoPlayAudioBriefing, enableHapticFeedback, themeMode ('system'|'light'|'dark'),
  currencyCode, dailyFocusGoalMinutes}` + `monogram`, `hasCustomPhoto`.
- Use cases (`Either`): `GetUserProfileUseCase`, `SaveUserProfileUseCase`, `PickProfileAvatarUseCase` (`image_picker`).
- `ProfileBloc` is an **app-wide lazy singleton**. State: `ProfileState{status, profile, errorMessage}`.
  Events: `LoadProfile`, `UpdateProfileIdentity`, `SelectAvatarPreset`, `PickAvatarPhoto`,
  `ClearCustomAvatarPhoto`, the `Toggle…` card/feature switches, `ChangeThemeModePreference`,
  `ToggleDarkModePreference`, `ChangeCurrencyPreference`, `ChangeDailyFocusGoal`, `ResetProfilePreferences`.
- **Who reads it:** `main.dart` (theme mode + currency), `MainNavigationShell` (show/hide quick ball),
  `TodayHubPage` (which cards to show).
- UI: `ProfileSettingsSheet` (opened from the Today Hub header and from the Command Palette),
  `UserAvatarWidget`.

### 11.8 Quick Capture

**Files:** `features/quick_capture/…`

```
FloatingQuickBall → QuickCaptureSheet.show(mode: text | voice | scan)
  typing → ParseQuickCaptureText → QuickCaptureIntentParser (pure Dart, rule-based)
         → ParsedQuickCaptureIntentEntity {detectedIntent: expense | reminder | habit | note,
            amount, time, isTomorrow, priority, isIncome, category, paymentMode, noteTag}
  user edits the detected fields → SubmitQuickCapture(QuickCaptureSubmissionEntity)
  → SubmitQuickCaptureUseCase → QuickCaptureRepository.save{Transaction|Reminder|Habit|Note}
  → effect QuickCaptureSubmitted(QuickCaptureResult{intent, summary, targetTabIndex})
  → shell re-keys the tabs and shows a "View" snackbar
```

- `QuickCaptureLocalDataSourceImpl` writes to the Drift tables directly for expenses, reminders and
  notes, calls `AddHabitUseCase` for habits, and schedules a notification for a timed reminder.
- 🟡 **Voice and Scan are simulated input.** There is no speech-to-text or OCR package. Voice mode
  offers sample phrases and a text field; Scan mode offers receipt/document presets with editable
  text. Everything after the text (parsing, saving) is real.

### 11.9 Command Palette (Spotlight Search)

**Files:** `features/command_palette/…` · opened from the quick ball's Spotlight button via
`GlobalCommandPaletteSheet.show`.

- `CommandPaletteLocalDataSourceImpl` builds search entries **by calling other features' use cases**
  (habits, timeline, planner items, transactions, subscriptions, IOUs, notes, vault items). Each
  module loads separately, so one failing module does not break the rest (`failedModules` /
  `isPartial` in the state).
- Vault entries are returned only when security is off or the master session is unlocked.
- `CommandPaletteBloc`: events `LoadCommandPalette`, `UpdateCommandPaletteQuery`,
  `SelectCommandPaletteModule`, `ClearCommandPaletteQuery`. State
  `CommandPaletteState{status, allEntries, failedModules, query, selectedModule, failure}` +
  `filteredEntries`, `moduleCounts`.
- Selecting a result switches to its tab (`targetTabIndex`); the palette can also open Quick Capture
  and the profile sheet.

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
| `AppText` | Themed text widget used across the app instead of raw `Text` + style |
| `AppBottomSheetContainer`, `AppSheetHandle` | Shared bottom-sheet chrome |
| `AnimatedCountText`, `StaggeredFadeSlide`, `PressableScale` | Small motion helpers |
| `BlocEffectListener` | Subscribes to a `BlocEffectMixin` effect stream for the widget's lifetime |
| `AppMonitorUserErrorHost`, `AppUserErrorBanner` | Global user-facing error banner, mounted in `MaterialApp.builder` |

`FloatingQuickBall` and `QuickCaptureSheet` now live in `features/quick_capture/presentation/widgets/`,
and `AudioBriefingSheet` in `features/today_hub/presentation/widgets/` (real TTS through `AppTtsService`).

| Widget | Purpose |
|---|---|
| `HabitBubbleWidget`, `SafeSpendMeterWidget` | Today Hub building blocks (compact habit rows with a single meta line and stacked streak + 7-day dots; animated progress and budget breakdown toggle) |
| `ExpandableTextWidget` | Reusable multi-line text widget with smooth `AnimatedSize` "Show more / Show less" toggle for long titles, notes, and insights |

### `core/bloc/`
- `bloc_status.dart`: `BlocStatus { initial, loading, success, failure }` (+ `isBusy`) for single-object states.
- `bloc_effect_mixin.dart`: `BlocEffectMixin<Event, State, Effect>` adds a broadcast `effects` stream
  and `emitEffect(...)` for things that must happen once (close a sheet, unlock callback). An effect
  emitted with no listener attached is dropped.
- `app_bloc_observer.dart`: forwards every transition and uncaught Bloc error to `AppMonitor`.

### `core/monitoring/app_monitor.dart`
`AppMonitor.instance` is an **in-process** monitor (no remote crash service): global Flutter /
platform error handlers and a release-mode fallback error widget, frame-timing (jank) observer,
breadcrumbs, `traceAsync` spans, startup duration, secret/PII redaction (`redact`), and
`friendlyMessage` / `toUserFriendlyError`, which turn any error into user-safe wording. Errors
recorded with `notifyUser: true` appear in the global `AppUserErrorBanner`.

### `core/services/tts/`
`AppTtsService` interface (`speak`, `pause`, `resume`, `stop`, `setRate`) with io, web and stub
implementations chosen by conditional import; get one with `getAppTtsService()`.

### `core/utils/`
`currency_utils.dart` (`CurrencyUtils.format`, `setCurrency`, `supportedCurrencies`), `date_utils.dart`,
`validators.dart`, `snackbar_utils.dart`.

### `core/constants/`
- `app_constants.dart`: timeouts, storage keys for a future auth system (JWT, onboarding), page size 10, retries.
- `string_constants.dart`: UI strings (`appName`, `holdToSpeak`, `quickType`, `scanText`, …).
- `asset_paths.dart`.

### `core/network/` (not used yet)
`ApiClient` (Dio), `ApiEndpoints`, `AuthInterceptor`, `ErrorInterceptor`, `LoggingInterceptor`,
`NetworkInfo`. Prepared for future cloud sync.

### `core/error/`
Exceptions: `ServerException`, `CacheException`, `NetworkException`, `ValidationException`.
Failures: `ServerFailure`, `CacheFailure`, `NetworkFailure`, `ValidationFailure`.
`failure_mapper.dart` has `mapExceptionToFailure` and `guardRepositoryCall<T>(action)`, which runs a
data-layer call and returns `Right(result)` or `Left(Failure)`; unknown errors are logged and mapped
to a generic message. Used by the newer features (Profile, Quick Capture, Command Palette, Security
use cases); the older features do not use it.

---

## 13. Theme & Design System

`lib/config/theme/`:
- `app_colors.dart`: brand `primary #6366F1` (indigo), plus module colors:
  Time/Planner `#F59E0B` amber · Money `#10B981` emerald · Notes `#0EA5E9` sky · Vault `#8B5CF6` violet.
  Each has `Light`/`Dark` variants, and there's a full dark palette (`darkScaffoldBackground`, `darkCardBackground`, …).
- `app_text_styles.dart`, `app_spacing.dart`, `app_radius.dart`, `app_decorations.dart`
  (e.g. `floatingBar`), `app_theme.dart` (`lightTheme`, `darkTheme`).
- Font: **Inter**. Theme mode comes from the profile (`system` by default, or forced `light` / `dark`),
  with a 220ms animated switch.
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

About 40 test files. Counts are top-level `test` / `testWidgets` / `blocTest` calls.

| Area | Files | ~Tests |
|---|---|---|
| Database | `test/database_test.dart` (schema, CRUD, seeder) | 10 |
| Core | `core/core_pipeline_test.dart`, `core/ui_polish_and_overflow_test.dart`, `core/widgets/{app_text_and_theme,habit_bubble_widget}_test.dart` | 16 |
| Monitoring | `core/monitoring/app_monitor_test.dart` | 12 |
| Notifications | `core/notifications/notification_service_test.dart` (+ `fake_notification_service.dart`, the **test double**) | 6 |
| Security | `features/security/security_test.dart`, `…/bloc/security_bloc_test.dart` | 21 |
| Planner | datasource, bloc, page and 5 widget test files | 18 |
| Money | datasource, `money_workflows_test.dart`, bloc, shell | 11 |
| Notes | datasource, page | 4 |
| Today Hub | datasource, page, audio briefing sheet | 6 |
| Quick Capture | intent parser, submit use case, bloc | 20 |
| Command Palette | `command_palette_test.dart` | 6 |
| Navigation / Profile | `navigation_bloc_test.dart`, `profile_test.dart`, `dark_mode_test.dart` | 7 |
| Cross-cutting | `device/device_matrix_test.dart`, `performance/app_performance_test.dart`, `security/vulnerability_audit_test.dart`, `integration/app_e2e_journey_test.dart` | 15 |
| App boot / widgets | `widget_test.dart`, `app_dropdown_menu_test.dart` | 4 |
| Device run | `integration_test/app_production_test.dart` (needs a device/emulator; not part of `flutter test`) | 1 |

`test/failures/` holds golden-diff PNGs left by a failed golden run; they are output, not tests.

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
| Habits: CRUD, toggle, skip, streaks, per-date history, reminders, daily reset | ✅ Real (DB + `habit_details` + notifications) |
| Today timeline | ✅ Real (DB; add / edit / delete via `TimelineEditorSheet`) |
| Safe-spend meter on Today | ✅ Real (`GetDailySpendSnapshotUseCase`) |
| Audio briefing / TTS | ✅ Real (`AppTtsService`; reads habits, timeline, planner and spend) |
| Quick Capture: typed text | ✅ Real (rule-based intent parsing + Expense, Reminder, Habit, Note persistence + View navigation) |
| Quick Capture: voice / scan input | 🟡 Simulated (sample phrases / scan presets; no speech-to-text or OCR package) |
| Command Palette search | ✅ Real (reads all modules through their use cases) |
| Profile: name, avatar, theme mode, currency, card toggles | ✅ Real (SharedPreferences) |
| Planner reminders CRUD + recurrence + checklist | ✅ Real (DB) |
| Planner notifications | ✅ Real (local notifications) |
| Snooze | 🟡 Schedules a notification; doesn't change the item |
| Pomodoro | ✅ Real (SharedPreferences settings, session log, 7-day chart, Zen mode, subtask sync, distraction pad) |
| Countdowns | ✅ Real (SharedPreferences + notifications) |
| Money: transactions (add / edit / delete), budget, category limits, accounts + transfers, subscriptions, IOUs, insights, period views | ✅ Real (DB + UI) |
| Money: budget alerts, Money lock, currency | ✅ Real |
| Money: subscription auto-kill | 🟡 Flag only; nothing cancels a subscription |
| Notes CRUD, pin, tags, scratchpad | ✅ Real |
| Note → planner task | ✅ Real (direct DB insert) |
| Vault built-in passwords / documents | 🔴 Hardcoded mock data |
| Vault user-added passwords / documents | 🟡 Real but page-level: metadata in SharedPreferences, secrets in secure storage; no DB table, not in the data layer |
| Vault lock (PIN / pattern / biometric / decoy / lockout / auto-lock) | ✅ Real |
| Cloud sync / API | 🔴 Not started (Dio layer scaffolded) |
| Real speech-to-text, camera OCR, location triggers, TTS reminders | 🔴 Not started (in PRD) |

---

## 18. Known Issues & Tech Debt

1. **Notification ID mismatch.** The full reminder sheet hashes `'$title$date$time$repeatType'`
   (with `DateTime`/`TimeOfDay` `toString()`), but delete hashes `'${title}${date}${startTime}'`.
   Deleting a reminder created from the full sheet probably **doesn't cancel** its notification.
   Fix idea: derive the notification ID from the DB `id`.
2. **Habit daily reset happens on read.** `getHabits()` clears `isDoneToday` when
   `lastCompletedDate` is not today (fixed). A missed day still isn't checked against `streakDays`.
3. **Blocs aren't shared across tabs.** Quick capture refreshes the tabs (re-key), but converting a
   note to a task, or adding a countdown to the planner, won't refresh other tabs until they reload.
   Today Hub's timeline doesn't read `PlannerItems` at all.
4. **Logic in the UI.** `planner_page.dart` (~3.9k lines) holds notification scheduling, Pomodoro
   and countdown persistence. `vault_page.dart` (~2.7k lines) holds all persistence for user-added
   vault items. Good candidates to move into use cases / data sources.
5. **Notes page writes to the DB directly** (`sl<AppDatabase>()`), bypassing clean architecture.
   `QuickCaptureLocalDataSourceImpl` also writes other features' tables directly.
6. **Two coding styles** (plain `Future` + state classes vs. `Either` + `BlocStatus`), see
   [section 4](#4-architecture-clean-architecture--bloc). Still unused: `core/network`, `HomePage`,
   auth keys in `AppConstants`, `DatabaseSeeder.clearMoneyDemoDataOnce`.
7. **Missing try/catch** in `PlannerBloc` mutation handlers (add / update / delete / toggle / clear).
   The error still reaches `AppBlocObserver`, but the Bloc emits no error state.
8. **Monthly recurrence** doesn't handle day 29–31 in short months, and monthly notifications fire only once.
9. **Duplicate lock state** in Vault (page `_isUnlocked` + Bloc `isUnlocked`).
10. **`.env` is bundled as an asset.** Never put real secrets in it.
11. **Android package** is `com.dailylifeos.app` (renamed from the template `com.example.fine_route`).
12. Equatable `props` on some events/entities are incomplete (e.g. `AddPlannerItem`, `HabitEntity`),
    so two different objects can compare equal.
13. **`habit_details` is outside Drift.** It is created with raw SQL in the Today Hub data source,
    so it has no generated classes and no migration coverage.
14. **Migrations only add.** `_ensureSchemaIntegrity` creates missing tables/columns and swallows
    errors; a rename, type change or back-fill silently does nothing unless coded by hand.
15. **Vault mock data and real data are mixed.** Hardcoded demo items are merged with user items,
    and "deleting" a demo item just hides its id.
16. **Seeded demo data ships to real users.** First launch inserts demo habits, transactions,
    subscriptions and IOUs; the one-time Money cleanup helper is never called.

---

## 19. How-To Recipes

### Add a new feature module
1. Create `lib/features/<name>/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{bloc,pages,widgets}}`.
2. If it needs persistence, add a Drift table in `app_database.dart`, add it to `@DriftDatabase(tables: …)`,
   bump `schemaVersion`, and run build_runner (the missing table is created automatically).
3. Write Entity → Repository (abstract) → UseCases → Model → LocalDataSource → RepositoryImpl.
4. Write Event/State/Bloc (export event and state from the bloc file).
5. Register everything in `injection_container.dart` (lazy singletons + `registerFactory` for the Bloc).
6. Page: `BlocProvider(create: (_) => sl<XBloc>()..add(const LoadX()), child: _XView())`.
7. Add it to `MainNavigationShell._pages` or open it as a sheet.
8. Add tests using `AppDatabase(NativeDatabase.memory())`.

### Add a column to an existing table
```dart
// 1. app_database.dart — the column needs a default or must be nullable
TextColumn get myField => text().withDefault(const Constant(''))();
// 2. schemaVersion => 5;
// 3. No migration code: _ensureSchemaIntegrity adds the missing column on upgrade / next open.
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
| **Quick-Capture** | Floating ball for voice/type/scan input |
| **Spotlight / Command Palette** | Search sheet across all modules |
| **Effect** | One-shot Bloc output (`BlocEffectMixin`), as opposed to state |
| **BlocStatus** | `initial / loading / success / failure` field used by the newer single-object states |
| **Money mode** | Being inside the Money tab: main bottom bar hidden, Money's own bar shown |
| **Master session** | In-memory "vault unlocked" flag in the security data source |
| **AppMonitor** | In-process error / performance monitor and friendly-error mapper |

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
