# 📘 Daily Life OS — Comprehensive Architecture & Knowledge Base

> **Document Version:** 1.0.0  
> **Target Audience:** Developers, Maintainers, and AI Agents working on **Daily Life OS**.  
> **Purpose:** Detailed reference manual explaining the architecture, data pipeline, module-by-module functionalities, database schemas, function implementations, and developer guides.

---

## 📑 Table of Contents
1. [Executive Summary & Product Vision](#1-executive-summary--product-vision)
2. [High-Level System Architecture](#2-high-level-system-architecture)
3. [End-to-End Architectural Data Flow](#3-end-to-end-architectural-data-flow)
4. [Module-by-Module Technical Deep Dive](#4-module-by-module-technical-deep-dive)
   - [4.1 Navigation Shell & Quick Capture](#41-navigation-shell--quick-capture)
   - [4.2 Today Hub (Command Center)](#42-today-hub-command-center)
   - [4.3 Planner & Focus Timer](#43-planner--focus-timer)
   - [4.4 Money Manager](#44-money-manager)
   - [4.5 Notes & Daily Scratchpad](#45-notes--daily-scratchpad)
   - [4.6 Secure Vault](#46-secure-vault)
5. [Drift SQLite Database Schema & Persistence](#5-drift-sqlite-database-schema--persistence)
6. [Dependency Injection (`get_it`) Wiring](#6-dependency-injection-get_it-wiring)
7. [Design System & Theme Tokens](#7-design-system--theme-tokens)
8. [Shared Core Widgets Library](#8-shared-core-widgets-library)
9. [Testing Strategy & Test Suites](#9-testing-strategy--test-suites)
10. [Developer Extension Playbook](#10-developer-extension-playbook)

---

## 1. Executive Summary & Product Vision

### 1.1 The Core Problem
Users typically juggle 4 to 6 disparate apps every day:
- A to-do list / calendar app for daily schedule.
- An expense tracker for logging money spent.
- A note-taking app for random thoughts and checklists.
- A password manager or gallery vault for credentials and warranties.

These apps operate in isolation: a bill reminder in a calendar never automatically updates an expense ledger, and logging a purchased gadget never prompts to save the receipt and set a warranty reminder.

### 1.2 The Solution
**Daily Life OS** is an offline-first personal operating system built with Flutter. It connects:
- **Time** (Reminders, Schedules, Focus Pomodoro)
- **Money** (Expenses, Monthly Budgets, Subscriptions, IOU Debts)
- **Mind** (Notes, Quick Scratchpad, Voice Audio Briefings)
- **Security** (AES-256 Passwords, Document & Warranty Locker, Decoy Mode)

All modules integrate into a unified **Today Hub** dashboard, coupled with a persistent floating **Quick-Capture Bar** accessible from anywhere.

---

## 2. High-Level System Architecture

Daily Life OS strictly adheres to **Clean Architecture** combined with a **Feature-First** structure.

```
lib/
 ├── config/                 # App-wide routing and design system
 │    ├── routes/            # go_router configuration
 │    └── theme/             # Colors, styles, radius, spacing, themes
 ├── core/                   # Shared cross-cutting infrastructure
 │    ├── constants/         # App constants, string literals, asset paths
 │    ├── database/          # Drift (SQLite) ORM and Database Seeder
 │    ├── error/             # Failures and Exception classes
 │    ├── network/           # Dio client, interceptors, connectivity info
 │    ├── usecase/           # Generic UseCase<Type, Params> abstraction
 │    ├── utils/             # Formatters, date helpers, validators
 │    └── widgets/           # Global design system widgets
 ├── di/                     # Dependency Injection with get_it
 └── features/               # Isolated feature modules
      ├── today_hub/
      ├── planner/
      ├── money/
      ├── notes/
      ├── vault/
      └── navigation/
```

### The Three Feature Layers:
1. **Domain Layer (`domain/`)**:
   - Contains pure business logic: **Entities**, **Use Cases**, and **Repository Interfaces**.
   - **Zero external dependencies**: Contains pure Dart code with no UI, Drift, or Flutter imports.
2. **Data Layer (`data/`)**:
   - Contains **Data Sources** (Drift local database queries), **Models** (mapping between Drift generated row classes and Domain entities), and **Repository Implementations**.
   - Depends directly on the Domain layer.
3. **Presentation Layer (`presentation/`)**:
   - Contains **BLoCs**, **Events**, **States**, **Pages**, and **Feature Widgets**.
   - Reacts to user interaction by dispatching BLoC events and rendering based on emitted states.

---

## 3. End-to-End Architectural Data Flow

Every state transition and database query follows a predictable, unidirectional cycle:

```
[User Action in UI]
        │
        ▼ (1)
[BLoC Event Dispatched]
        │
        ▼ (2)
[BLoC Handler Invokes UseCase]
        │
        ▼ (3)
[UseCase Calls Repository Interface]
        │
        ▼ (4)
[Repository Implementation Calls LocalDataSource]
        │
        ▼ (5)
[LocalDataSource Executes Drift / SQLite Query]
        │
        ▼ (6)
[Drift Returns Raw Row Data / Companion]
        │
        ▼ (7)
[Model Mappers Convert Drift Row -> Domain Entity]
        │
        ▼ (8)
[Repository Returns Entity to UseCase]
        │
        ▼ (9)
[BLoC Emits Loaded State with Immutable Entities]
        │
        ▼ (10)
[BlocBuilder Rebuilds UI Reactively]
```

### Error Handling Protocol:
- If a database operation fails, the `DataSource` throws a typed exception (e.g., `DatabaseException`).
- The `RepositoryImpl` catches the exception and returns a `Failure` or throws an expected domain error.
- The `BLoC` emits an error state (e.g., `NotesError(message: ...)`), allowing the UI to present a snackbar or retry state without crashing.

---

## 4. Module-by-Module Technical Deep Dive

---

### 4.1 Navigation Shell & Quick Capture
- **Location:** `lib/features/navigation/presentation/pages/main_navigation_shell.dart`
- **Core Component:** `MainNavigationShell`
- **State Management:** Local `StatefulWidget` using `IndexedStack` to preserve state across tabs.

#### Key Functions & Implementation:
1. **`_buildFloatingQuickCaptureBar()`**:
   - Renders a floating frosted pill 74px from the bottom, above the `BottomNavigationBar`.
   - Contains:
     - `[Hold to Speak]`: Opens `QuickCaptureSheet` in voice recording mode.
     - `[Quick Type]`: Opens `QuickCaptureSheet` in text input mode.
     - `[Scan Bill/Text]`: Opens `QuickCaptureSheet` in camera/OCR mode.
2. **`QuickCaptureSheet._parseIntent()`** (`lib/core/widgets/quick_capture_sheet.dart`):
   - Natural language classification that categorizes inputs in real-time as the user types:
     - **Expense**: matches words like `spent`, `paid`, `bought`, `₹`, `rs`, `bill`, `cost`.
     - **Vault**: matches words like `password`, `pin`, `secret`, `warranty`.
     - **Reminder**: matches words like `remind`, `at`, `tomorrow`, `pm`, `am`, `meeting`.
     - **Note**: default fallback for open thoughts and ideas.

---

### 4.2 Today Hub (Command Center)
- **Location:** `lib/features/today_hub/`
- **Presentation:** `TodayHubPage`, `_LoadedView`, `_LoadingView`
- **BLoC:** `TodayHubBloc` (`today_hub_event.dart`, `today_hub_state.dart`)
- **Domain:** `HabitEntity`, `TimelineItemEntity`
- **Database Tables:** `Habits`, `TimelineItems`

#### Business Logic & Functions:
1. **`LoadTodayHub` Event (`_onLoad` in `TodayHubBloc`)**:
   - Calls `GetHabitsUseCase` and `GetTodayTimelineUseCase`.
   - Computes habit completion counts (`completedHabits`).
   - Emits `TodayHubLoaded(habits: ..., timelineItems: ...)`.
2. **`ToggleHabit` Event (`_onToggleHabit` in `TodayHubBloc`)**:
   - Calls `ToggleHabitUseCase(habitId)`.
   - Flips `isDoneToday`, increments or decrements `streakDays`, and updates `lastCompletedDate`.
   - Automatically reloads the refreshed habits list.
3. **`ToggleTimelineItem` Event (`_onToggleTimelineItem` in `TodayHubBloc`)**:
   - Calls `ToggleTimelineItemUseCase(timelineId)`.
   - Toggles `isDone` boolean in SQLite.
4. **Safe-to-Spend Calculation Formula** (`SafeSpendMeterWidget`):
   $$\text{Daily Safe Spend} = \frac{\text{Monthly Budget} - (\text{Fixed Bills} + \text{Spent So Far})}{\text{Days Remaining in Current Month}}$$
   - Prevents end-of-month budget depletion by setting dynamic daily limits.
5. **Audio Briefing Pill (`AudioBriefingSheet.show(context)`)**:
   - Opens the modal TTS preview summarizing today's active tasks and remaining budget.

---

### 4.3 Planner & Focus Timer
- **Location:** `lib/features/planner/`
- **Presentation:** `PlannerPage`
- **BLoC:** `PlannerBloc` (`planner_event.dart`, `planner_state.dart`)
- **Domain:** `PlannerItemEntity`
- **Database Table:** `PlannerItems`

#### Business Logic & Functions:
1. **`LoadPlanner` Event**:
   - Fetches all scheduled items for the chosen ISO date (defaults to `DateTime.now()`).
2. **`AddPlannerItem` Event**:
   - Inserts a new planner task with `title`, `date`, `startTime`, `category`, `colorValue`, and `iconCodePoint`.
3. **`TogglePlannerItem` Event**:
   - Toggles task completion state (`isDone`).
4. **`DeletePlannerItem` Event**:
   - Permanently deletes the reminder from SQLite.
5. **Interactive Reminder Sheet (`_showSetReminderSheet()` in `PlannerPage`)**:
   - Lets users specify reminder title, pick a custom date (`showDatePicker`), pick a time (`showTimePicker`), and choose from 5 categories: *Personal*, *Work*, *Health*, *Finance*, and *Important*.
6. **Pomodoro Focus Timer State Machine (`_PlannerViewState`)**:
   - Local state: `_secondsRemaining` (defaults to 1500s / 25 mins), `_isTimerRunning`, `_isWorkSprint`.
   - `_toggleTimer()`: Starts or pauses the `Timer.periodic(1 second)`.
   - `_resetTimer()`: Resets counter to 25m (Work Sprint) or 5m (Short Break).
   - Automatically cycles to Short Break when sprint reaches 0.

---

### 4.4 Money Manager
- **Location:** `lib/features/money/`
- **Presentation:** `MoneyManagerPage`
- **BLoC:** `MoneyBloc` (`money_event.dart`, `money_state.dart`)
- **Domain:** `TransactionEntity`, `SubscriptionEntity`, `IouEntity`, `BudgetEntity`
- **Database Tables:** `Transactions`, `BudgetSettings`, `Subscriptions`, `IouEntries`

#### Business Logic & Functions:
1. **`LoadMoney` Event (`_onLoad` in `MoneyBloc`)**:
   - Concurrently loads:
     - `GetRecentTransactionsUseCase()`
     - `GetBudgetUseCase()`
     - `GetSubscriptionsUseCase()`
     - `GetIousUseCase()`
   - Emits `MoneyLoaded` containing the unified financial snapshot.
2. **`AddTransaction` Event**:
   - Saves new transaction (title, category, amount, mode [UPI, Card, Cash], date, expense/income).
   - Triggers dynamic budget recalculation.
3. **`ToggleAutoKill` Event**:
   - Toggles `autoKillEnabled` flag on subscriptions. When enabled, users receive automated cancellation reminders 48 hours prior to renewal.
4. **`SettleIou` & `AddIou` Events**:
   - Tracks mini-ledger entries for money lent or borrowed.
   - `SettleIou` toggles `isSettled` state with full timestamp recording.

---

### 4.5 Notes & Daily Scratchpad
- **Location:** `lib/features/notes/`
- **Presentation:** `NotesPage`
- **BLoC:** `NotesBloc` (`notes_event.dart`, `notes_state.dart`)
- **Domain:** `NoteEntity`
- **Database Table:** `Notes`

#### Business Logic & Functions:
1. **`LoadNotes` Event**:
   - Queries all notes from Drift, sorted by `isPinned DESC, updatedAt DESC`.
2. **`AddNote` & `UpdateNote` Events**:
   - Supports creating and updating note content, title, color accent (from curated 6-color palette), and tag strings.
3. **`TogglePinNote` & `DeleteNote` Events**:
   - `TogglePinNote` updates pin status, immediately floating priority notes to the top.
   - `DeleteNote` removes the note with an accompanying `ConfirmationDialog`.
4. **Daily Scratchpad (`_loadScratchpad`, `_saveScratchpadAsNote`)**:
   - Real-time scratchpad persisted in `SharedPreferences` (`daily_scratchpad_content`).
   - "Save as Note" button converts unorganized thoughts directly into a full database note.
5. **Context Menu Actions (`AppDropdownMenu`)**:
   - **Edit**: Opens bottom sheet editor with pre-filled values.
   - **Pin / Unpin**: Toggles pinned state.
   - **Copy Text**: Copies note title and content to system clipboard via `Clipboard.setData`.
   - **Add to Planner**: Directly converts note title and content into a scheduled Planner reminder item.
   - **Delete**: Triggers deletion modal confirmation.

---

### 4.6 Secure Vault
- **Location:** `lib/features/vault/`
- **Presentation:** `VaultPage`
- **BLoC:** `VaultBloc` (`vault_event.dart`, `vault_state.dart`)
- **Domain:** `VaultItemEntity`

#### Business Logic & Functions:
1. **`LoadVault` Event**:
   - Loads stored password entries and document/warranty records.
2. **`ToggleDecoyMode` Event**:
   - Toggles `isDecoyMode`. When active, only non-sensitive demo accounts appear.
   - Protects users under duress (Panic PIN feature specified in PRD).
3. **Warranty Expiry Alerts**:
   - Identifies approaching warranty expiration dates and displays remaining days warnings.

---

## 5. Drift SQLite Database Schema & Persistence

All persistence is managed by **Drift** in `lib/core/database/app_database.dart`.

### Tables Overview

| Table Name | Entity | Key Columns & Types | Description |
| :--- | :--- | :--- | :--- |
| **`habits`** | `HabitEntity` | `id` (Int PK), `title` (Text), `iconCodePoint` (Int), `colorValue` (Int), `streakDays` (Int), `isDoneToday` (Bool), `lastCompletedDate` (Text) | Tracks habits, daily completion, and ongoing streaks |
| **`timeline_items`** | `TimelineItemEntity` | `id` (Int PK), `time` (Text), `title` (Text), `category` (Text), `colorValue` (Int), `iconCodePoint` (Int), `isDone` (Bool), `action` (Text), `date` (Text) | Chronological tasks shown in Today Hub |
| **`transactions`** | `TransactionEntity` | `id` (Int PK), `title` (Text), `category` (Text), `amount` (Real), `mode` (Text: UPI/Card/Cash), `date` (Text), `type` (Text: expense/income) | Financial transaction log |
| **`budget_settings`** | `BudgetEntity` | `id` (Int PK, default 1), `monthlyBudget` (Real), `fixedBills` (Real) | User budget preferences for safe-spend logic |
| **`subscriptions`** | `SubscriptionEntity`| `id` (Int PK), `name` (Text), `amount` (Real), `renewalDate` (Text), `autoKillEnabled` (Bool) | Recurring bills and cancellation tracking |
| **`iou_entries`** | `IouEntity` | `id` (Int PK), `person` (Text), `amount` (Real), `type` (Text: lent/borrowed), `note` (Text), `isSettled` (Bool) | Peer-to-peer debts ledger |
| **`notes`** | `NoteEntity` | `id` (Int PK), `title` (Text), `content` (Text), `colorValue` (Int), `isPinned` (Bool), `tags` (Text), `createdAt` (Text), `updatedAt` (Text) | Structured notes and brain dumps |
| **`planner_items`** | `PlannerItemEntity` | `id` (Int PK), `title` (Text), `date` (Text), `startTime` (Text), `category` (Text), `isDone` (Bool), `notes` (Text) | Scheduled calendar tasks & reminders |

### Database Seeding (`DatabaseSeeder`)
- Defined in `lib/core/database/database_seeder.dart`.
- Triggered on launch via `DatabaseSeeder.seedIfEmpty(db)` in `main.dart`.
- If `habits` table is empty, pre-populates initial records for habits, timeline items, budget settings, transactions, subscriptions, and notes so the UI never launches into an empty screen on first run.

---

## 6. Dependency Injection (`get_it`) Wiring

All application singletons, data sources, repositories, use cases, and BLoC factories are registered in `lib/di/injection_container.dart` via `initDependencies()`.

### Registration Hierarchy (Bottom-Up):
1. **Core Database:** `sl.registerLazySingleton<AppDatabase>(() => ...)`
2. **DataSources:** Local data sources receiving `sl<AppDatabase>()`
3. **Repositories:** Repository implementations receiving their respective data sources
4. **UseCases:** Atomic business actions receiving their repository interface
5. **BLoCs:** Factory registrations (`sl.registerFactory<T>()`) instantiated freshly per page lifecycle

---

## 7. Design System & Theme Tokens

The design system enforces a sleek, modern, high-contrast dark and light theme.

- **Theme Files:** `lib/config/theme/`
  - `app_colors.dart`:
    - `primary`: Deep Indigo `#4F46E5`
    - `secondary`: Cyan / Sky `#06B6D4`
    - Module Accents:
      - Time: `#3B82F6` (Blue)
      - Money: `#10B981` (Emerald Green)
      - Notes: `#F59E0B` (Amber Gold)
      - Vault: `#8B5CF6` (Purple)
  - `app_radius.dart`: Standardized radiuses (`radiusSm: 8`, `radiusMd: 14`, `radiusLg: 20`, `radiusFull: 999`).
  - `app_spacing.dart`: Standard spacing constants and `SizedBox` helpers (`gapH8`, `gapH16`, `gapW12`, etc.).
  - `app_text_styles.dart`: High-legibility typography scale based on font family `DMSans`.
  - `app_decorations.dart`: Reusable card shadows, gradient banners, and floating bar decorations.

---

## 8. Shared Core Widgets Library

Located in `lib/core/widgets/`:

1. **`AppDropdownMenu<T>`**:
   - Custom overlay dropdown avoiding standard flutter popup limitations.
   - Provides smooth tap outside detection, custom styling, and item selection callbacks.
2. **`ConfirmationDialog`**:
   - Clean alert dialog for confirming destructive operations (e.g., Note deletion).
3. **`AppShimmerLoader`**:
   - Skeleton card loaders displaying shimmering placeholders while data loads.
4. **`SafeSpendMeterWidget`**:
   - Custom progress meter visualizing daily expenses against remaining budget limits.
5. **`HabitBubbleWidget`**:
   - Animated circular bubble showing habit icon, streak counter, and tap-to-complete animations.
6. **`QuickCaptureSheet`**:
   - Universal bottom sheet capturing Voice, Text, and OCR scans with real-time intent parsing.
7. **`AudioBriefingSheet`**:
   - Daily overview sheet reading out time, tasks, and budgets via voice synthesis.

---

## 9. Testing Strategy & Test Suites

The test suite in `test/` ensures complete stability across business logic and user flows:

1. **`database_test.dart`**:
   - Unit tests running on an in-memory SQLite database (`NativeDatabase.memory()`).
   - Verifies CRUD operations across `habits`, `notes`, `planner_items`, and `transactions`.
2. **`app_dropdown_menu_test.dart`**:
   - Widget tests verifying popup menu rendering, callback invocation, and tap-outside dismissal.
3. **`widget_test.dart`**:
   - Complete end-to-end smoke test validating:
     - 5-tab navigation switching (`Today`, `Planner`, `Money`, `Notes`, `Vault`).
     - Habit toggling and streak incrementation in Today Hub.
     - Note creation, daily scratchpad auto-syncing, pinning, and deletion.
     - Reminder scheduling in Planner.

To execute tests at any time:
```bash
flutter test
```

---

## 10. Developer Extension Playbook

### How to Add a New Table & Feature to Daily Life OS

When adding a new feature (e.g., *Habit Statistics* or *Goal Tracker*):

1. **Add Table Schema:**
   - Define table in `lib/core/database/app_database.dart`:
     ```dart
     class Goals extends Table {
       IntColumn get id => integer().autoIncrement()();
       TextColumn get title => text()();
       RealColumn get targetAmount => real()();
     }
     ```
   - Run code generator:
     ```bash
     dart run build_runner build --delete-conflicting-outputs
     ```
2. **Create Domain Entity & Repository Interface:**
   - Create `lib/features/goals/domain/entities/goal_entity.dart`.
   - Create `lib/features/goals/domain/repositories/goal_repository.dart`.
3. **Implement Data Layer:**
   - Create `GoalLocalDataSource` querying `AppDatabase`.
   - Create `GoalRepositoryImpl` implementing the domain interface and mapping Drift models to entities.
4. **Create Use Cases:**
   - E.g., `GetGoalsUseCase`, `AddGoalUseCase`.
5. **Implement BLoC:**
   - Define `GoalsEvent`, `GoalsState`, and `GoalsBloc`.
6. **Register in DI:**
   - Register DataSources, Repositories, UseCases, and BLoC in `lib/di/injection_container.dart`.
7. **Wire UI:**
   - Create page in `lib/features/goals/presentation/pages/goals_page.dart` with `BlocProvider`.
