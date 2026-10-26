# Daily Life OS — Master Functional Specification & Implementation Blueprint

> **File Location:** `PROJECT_FUNCTIONS_AND_IMPLEMENTATION_GUIDE.md`  
> **Status:** Implementation Master Specification  
> **Architecture Pattern:** Clean Architecture (Domain / Data / Presentation) + BLoC State Management + Drift SQLite Local Persistence + GetIt Dependency Injection  

---

## Table of Contents
1. [System Architecture & Layer Responsibilities](#1-system-architecture--layer-responsibilities)
2. [Complete Database Schema (Drift SQLite v2)](#2-complete-database-schema-drift-sqlite-v2)
3. [Domain Layer: All Entities & Field Specifications](#3-domain-layer-all-entities--field-specifications)
4. [Domain Layer: All Use Cases, Signatures & Return Types](#4-domain-layer-all-use-cases-signatures--return-types)
5. [Presentation Layer: All BLoCs, Events & States](#5-presentation-layer-all-blocs-events--states)
6. [Core Shared Widgets (All 18 Components & Purposes)](#6-core-shared-widgets-all-18-components--purposes)
7. [Screen-by-Screen Breakdown & UI Interaction Details](#7-screen-by-screen-breakdown--ui-interaction-details)
8. [Cross-Module Intelligent Workflows](#8-cross-module-intelligent-workflows)
9. [End-to-End Implementation Execution Checklist](#9-end-to-end-implementation-execution-checklist)

---

## 1. System Architecture & Layer Responsibilities

```
┌────────────────────────────────────────────────────────────────────────┐
│                          Presentation Layer                            │
│  Pages / Views ──► Specialized Widgets ──► BLoC (Events & States)     │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Calls UseCase (Params)
┌───────────────────────────────────▼────────────────────────────────────┐
│                             Domain Layer                               │
│  Entities (Pure Dart) ◄──► UseCases ◄──► Repository Interfaces (Contracts)
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Implemented By
┌───────────────────────────────────▼────────────────────────────────────┐
│                             Data Layer                                 │
│  Repository Implementations ──► Local DataSources                     │
│  Drift SQLite Database ──► FlutterSecureStorage ──► LocalAuth Service  │
│  Local Notification Service ──► System SharedPreferences               │
└────────────────────────────────────────────────────────────────────────┘
```

### Layer Rules
- **Domain Layer:** Contains zero Flutter UI dependencies (`dart:core` only). All data models are immutable entities.
- **Data Layer:** Handles database persistence (`AppDatabase`), encryption (`FlutterSecureStorage`), biometric hardware interfacing (`LocalAuthentication`), and OS notification channels (`NotificationService`).
- **Presentation Layer:** Uses `flutter_bloc` for all reactive state flows. Screens dispatch events and render based on distinct states (Initial, Loading, Loaded, Error).

---

## 2. Complete Database Schema (Drift SQLite v2)

Database defined in `lib/core/database/app_database.dart` with schema version 2:

### Table 1: `Habits`
- **Purpose:** Stores recurring daily habits, tracking streaks and daily completion.
- **Columns:**
  - `id` (`IntColumn`, AutoIncrement, PrimaryKey): Unique habit identifier.
  - `title` (`TextColumn`): Title of the habit (e.g., "Drink 2L Water", "Morning Run").
  - `iconCodePoint` (`IntColumn`): Material icon code point.
  - `colorValue` (`IntColumn`): ARGB color int for visual categorization.
  - `streakDays` (`IntColumn`, Default 0): Consecutive days maintained.
  - `isDoneToday` (`BoolColumn`, Default false): Completion flag for current day.
  - `lastCompletedDate` (`TextColumn`, Nullable): ISO8601 date of last completion.
  - `createdAt` (`TextColumn`): Creation ISO8601 timestamp.

### Table 2: `TimelineItems`
- **Purpose:** Daily time-blocked events and schedule items for the Today Hub.
- **Columns:**
  - `id` (`IntColumn`, AutoIncrement, PrimaryKey): Unique item ID.
  - `time` (`TextColumn`): Display time string (e.g., "09:00 AM").
  - `title` (`TextColumn`): Task/Event summary.
  - `category` (`TextColumn`): Work, Health, Personal, Routine, etc.
  - `colorValue` (`IntColumn`): Visual accent color.
  - `iconCodePoint` (`IntColumn`): Icon representation.
  - `isDone` (`BoolColumn`, Default false): Completed status.
  - `action` (`TextColumn`): Associated deep action (e.g., "open_task", "start_call").
  - `date` (`TextColumn`): ISO8601 target date.

### Table 3: `Transactions`
- **Purpose:** Financial ledger recording all inflows and outflows.
- **Columns:**
  - `id` (`IntColumn`, AutoIncrement, PrimaryKey): Unique transaction ID.
  - `title` (`TextColumn`): Payee or description (e.g., "Grocery Store", "Freelance").
  - `category` (`TextColumn`): Food, Bills, Shopping, Transport, Salary, etc.
  - `amount` (`RealColumn`): Positive monetary value.
  - `mode` (`TextColumn`): Payment channel ('UPI', 'Card', 'Cash', 'Net Banking').
  - `iconCodePoint` (`IntColumn`): Icon representing category.
  - `date` (`TextColumn`): ISO8601 timestamp of transaction.
  - `type` (`TextColumn`, Default 'expense'): 'expense' or 'income'.

### Table 4: `BudgetSettings`
- **Purpose:** User financial targets and fixed recurring deductions.
- **Columns:**
  - `id` (`IntColumn`, PrimaryKey, Default 1): Singleton record.
  - `monthlyBudget` (`RealColumn`, Default 40000.0): Total budgeted expenditure limit.
  - `fixedBills` (`RealColumn`, Default 8000.0): Committed monthly costs (rent, utilities).

### Table 5: `Subscriptions`
- **Purpose:** Recurring subscription services and trial reminders.
- **Columns:**
  - `id` (`IntColumn`, AutoIncrement, PrimaryKey): Unique subscription ID.
  - `name` (`TextColumn`): Service name (e.g., "Netflix", "Spotify", "GitHub").
  - `amount` (`RealColumn`): Cost per cycle.
  - `renewalDate` (`TextColumn`): Next renewal ISO8601 date.
  - `autoKillEnabled` (`BoolColumn`, Default false): When true, schedules alerts before renewal.
  - `iconCodePoint` (`IntColumn`): Service icon.

### Table 6: `IouEntries`
- **Purpose:** Peer-to-peer debts, loans, and shared group expenses.
- **Columns:**
  - `id` (`IntColumn`, AutoIncrement, PrimaryKey): Unique entry ID.
  - `person` (`TextColumn`): Counterparty name.
  - `amount` (`RealColumn`): Amount owed or borrowed.
  - `type` (`TextColumn`): 'lent' (they owe user) or 'borrowed' (user owes them).
  - `note` (`TextColumn`): Reason/context (e.g., "Dinner bill split").
  - `date` (`TextColumn`): ISO8601 transaction date.
  - `isSettled` (`BoolColumn`, Default false): Settlement flag.

### Table 7: `Notes`
- **Purpose:** Rich notes, memos, checklists, and scratchpad storage.
- **Columns:**
  - `id` (`IntColumn`, AutoIncrement, PrimaryKey): Unique note ID.
  - `title` (`TextColumn`): Note heading.
  - `content` (`TextColumn`): Note body (plain text or markdown).
  - `colorValue` (`IntColumn`): Visual card color.
  - `isPinned` (`BoolColumn`, Default false): Sticky priority pin flag.
  - `tags` (`TextColumn`, Default ''): Comma-separated tag list (`#work,#ideas`).
  - `createdAt` (`TextColumn`): Creation ISO8601 timestamp.
  - `updatedAt` (`TextColumn`): Modification ISO8601 timestamp.

### Table 8: `PlannerItems`
- **Purpose:** Core planning tasks, calendar events, recurring routines, and reminders.
- **Columns:**
  - `id` (`IntColumn`, AutoIncrement, PrimaryKey): Unique item ID.
  - `title` (`TextColumn`): Task/event title.
  - `date` (`TextColumn`): Target ISO8601 date.
  - `startTime` (`TextColumn`, Nullable): Time format "HH:mm".
  - `endTime` (`TextColumn`, Nullable): Time format "HH:mm".
  - `category` (`TextColumn`): Work, Personal, Fitness, Study, etc.
  - `colorValue` (`IntColumn`): Color accent.
  - `iconCodePoint` (`IntColumn`): Material icon.
  - `isDone` (`BoolColumn`, Default false): Primary completion status.
  - `notes` (`TextColumn`): Additional descriptive notes.
  - `repeatType` (`TextColumn`, Default 'none'): 'none', 'daily', 'weekdays', 'weekly', 'monthly'.
  - `repeatDays` (`TextColumn`, Default ''): Comma-separated weekday numbers (e.g. '1,3,5').
  - `endDate` (`TextColumn`, Nullable): Repeat cutoff ISO8601 date.
  - `priority` (`TextColumn`, Default 'medium'): 'low', 'medium', 'high', 'urgent'.
  - `reminderOffsetMinutes` (`IntColumn`, Default 0): Notification offset (0, 5, 15, 30, 60, 1440).
  - `checklistJson` (`TextColumn`, Default '[]'): Embedded subtasks `[{"id":"1","title":"Step 1","isDone":false}]`.
  - `completedDates` (`TextColumn`, Default ''): Comma-separated list of completion dates for recurring events.

---

## 3. Domain Layer: All Entities & Field Specifications

### 3.1 `TransactionEntity` (`lib/features/money/domain/entities/transaction_entity.dart`)
- `int? id`: Unique ID.
- `String title`: Description/merchant.
- `String category`: Category name.
- `double amount`: Inflow or outflow amount.
- `String mode`: Payment method ('UPI', 'Card', 'Cash', 'Net Banking').
- `int iconCodePoint`: Visual icon.
- `DateTime date`: Timestamp of transaction.
- `String type`: 'expense' or 'income'.

### 3.2 `SubscriptionEntity` (`lib/features/money/domain/entities/subscription_entity.dart`)
- `int? id`: Unique ID.
- `String name`: Service name.
- `double amount`: Price per cycle.
- `DateTime renewalDate`: Next scheduled charge date.
- `bool autoKillEnabled`: True if pre-charge reminder is active.
- `int iconCodePoint`: Service icon.

### 3.3 `IouEntity` (`lib/features/money/domain/entities/iou_entity.dart`)
- `int? id`: Unique ID.
- `String person`: Person's name.
- `double amount`: Amount.
- `String type`: 'lent' or 'borrowed'.
- `String note`: Purpose/context.
- `DateTime date`: Date logged.
- `bool isSettled`: True if settled.

### 3.4 `HabitEntity` (`lib/features/today_hub/domain/entities/habit_entity.dart`)
- `int? id`: Unique ID.
- `String title`: Habit description.
- `int iconCodePoint`: Material icon.
- `int colorValue`: ARGB accent color.
- `int streakDays`: Current streak length.
- `bool isDoneToday`: Completed today flag.
- `DateTime? lastCompletedDate`: Timestamp of last completion.
- `DateTime createdAt`: Timestamp created.

### 3.5 `TimelineItemEntity` (`lib/features/today_hub/domain/entities/timeline_item_entity.dart`)
- `int? id`: Unique ID.
- `String time`: "08:00 AM".
- `String title`: Event or task summary.
- `String category`: Category badge.
- `int colorValue`: Color badge.
- `int iconCodePoint`: Icon.
- `bool isDone`: Completed status.
- `String action`: Deep-link action keyword.
- `DateTime date`: Target date.

### 3.6 `NoteEntity` (`lib/features/notes/domain/entities/note_entity.dart`)
- `int? id`: Unique ID.
- `String title`: Note heading.
- `String content`: Markdown text body.
- `int colorValue`: Visual card color.
- `bool isPinned`: Priority pinned flag.
- `List<String> tags`: Tag list.
- `DateTime createdAt`: Creation date.
- `DateTime updatedAt`: Last modification date.

### 3.7 `PlannerItemEntity` (`lib/features/planner/domain/entities/planner_item_entity.dart`)
- `int? id`: Unique ID.
- `String title`: Title.
- `DateTime date`: Main scheduled date.
- `String? startTime`: "09:00".
- `String? endTime`: "10:30".
- `String category`: Category.
- `int colorValue`: Color.
- `int iconCodePoint`: Icon.
- `bool isDone`: True if completed on target date.
- `String notes`: Markdown notes.
- `String repeatType`: 'none', 'daily', 'weekdays', 'weekly', 'monthly'.
- `List<int> repeatDays`: Weekday integers [1..7] for custom recurrences.
- `DateTime? endDate`: Optional recurring cutoff.
- `String priority`: 'low', 'medium', 'high', 'urgent'.
- `int reminderOffsetMinutes`: 0, 5, 15, 30, 60, 1440.
- `List<SubTask> checklist`: Subtasks `[SubTask(id: '1', title: 'Task 1', isDone: false)]`.
- `List<String> completedDates`: Dates on which recurring task was ticked off.

### 3.8 `CountdownItemEntity` (`lib/features/planner/domain/entities/countdown_item_entity.dart`)
- `String id`: Unique ID.
- `String title`: Milestone title.
- `DateTime targetDate`: Target deadline.
- `String category`: Category.
- `int colorValue`: Color.
- `int iconCodePoint`: Icon.

### 3.9 `SecurityConfigEntity` (`lib/features/security/domain/entities/security_config_entity.dart`)
- `bool isBiometricsEnabled`: Fingerprint/FaceID enabled.
- `int lockTimeoutMinutes`: Idle timeout duration.
- `bool autoLockOnAppExit`: Lock immediately on backgrounding.
- `bool isPinSet`: Has 4/6 digit master PIN.
- `bool isPatternSet`: Has 3x3 pattern lock.

---

## 4. Domain Layer: All Use Cases, Signatures & Return Types

| Module | Use Case Name | Input Parameters | Return Type |
|---|---|---|---|
| **Today Hub** | `GetHabitsUseCase` | `NoParams` | `Future<List<HabitEntity>>` |
| **Today Hub** | `ToggleHabitUseCase` | `int habitId` | `Future<void>` |
| **Today Hub** | `GetTodayTimelineUseCase`| `DateTime date` | `Future<List<TimelineItemEntity>>` |
| **Today Hub** | `ToggleTimelineItemUseCase`| `int itemId` | `Future<void>` |
| **Money** | `GetRecentTransactionsUseCase` | `int limit` | `Future<List<TransactionEntity>>` |
| **Money** | `GetBudgetUseCase` | `NoParams` | `Future<BudgetSettingsData>` |
| **Money** | `GetSubscriptionsUseCase`| `NoParams` | `Future<List<SubscriptionEntity>>` |
| **Money** | `GetIousUseCase` | `NoParams` | `Future<List<IouEntity>>` |
| **Money** | `AddTransactionUseCase` | `TransactionEntity` | `Future<void>` |
| **Money** | `UpdateBudgetUseCase` | `double monthly, double fixed` | `Future<void>` |
| **Money** | `ToggleAutoKillUseCase` | `int id, bool enabled` | `Future<void>` |
| **Money** | `AddIouUseCase` | `IouEntity` | `Future<void>` |
| **Money** | `SettleIouUseCase` | `int iouId` | `Future<void>` |
| **Notes** | `GetNotesUseCase` | `NoParams` | `Future<List<NoteEntity>>` |
| **Notes** | `AddNoteUseCase` | `NoteEntity` | `Future<void>` |
| **Notes** | `UpdateNoteUseCase` | `NoteEntity` | `Future<void>` |
| **Notes** | `DeleteNoteUseCase` | `int noteId` | `Future<void>` |
| **Notes** | `TogglePinNoteUseCase` | `int noteId` | `Future<void>` |
| **Planner** | `GetPlannerItemsUseCase` | `DateTime date` | `Future<List<PlannerItemEntity>>` |
| **Planner** | `AddPlannerItemUseCase` | `PlannerItemEntity` | `Future<void>` |
| **Planner** | `UpdatePlannerItemUseCase` | `PlannerItemEntity` | `Future<void>` |
| **Planner** | `TogglePlannerItemUseCase`| `int id, DateTime date` | `Future<void>` |
| **Planner** | `DeletePlannerItemUseCase`| `int id` | `Future<void>` |
| **Planner** | `ClearCompletedPlannerItemsUseCase` | `DateTime date` | `Future<void>` |
| **Vault** | `GetVaultPasswordsUseCase`| `NoParams` | `Future<List<VaultItemEntity>>` |
| **Vault** | `GetVaultDocumentsUseCase`| `NoParams` | `Future<List<VaultItemEntity>>` |

---

## 5. Presentation Layer: All BLoCs, Events & States

### 5.1 TodayHubBloc (`lib/features/today_hub/presentation/bloc/`)
- **Events:**
  - `LoadTodayHubEvent()`
  - `ToggleHabitEvent(int habitId)`
  - `ToggleTimelineItemEvent(int itemId)`
- **States:**
  - `TodayHubInitial()`
  - `TodayHubLoading()`
  - `TodayHubLoaded(List<HabitEntity> habits, List<TimelineItemEntity> timelineItems)`
  - `TodayHubError(String message)`

### 5.2 MoneyBloc (`lib/features/money/presentation/bloc/`)
- **Events:**
  - `LoadMoneyDataEvent()`
  - `AddTransactionEvent(TransactionEntity transaction)`
  - `UpdateBudgetEvent(double monthlyBudget, double fixedBills)`
  - `ToggleAutoKillEvent(int subscriptionId, bool autoKillEnabled)`
  - `AddIouEvent(IouEntity iou)`
  - `SettleIouEvent(int iouId)`
- **States:**
  - `MoneyInitial()`
  - `MoneyLoading()`
  - `MoneyLoaded(List<TransactionEntity> transactions, BudgetSettingsData budget, List<SubscriptionEntity> subscriptions, List<IouEntity> ious)`
  - `MoneyError(String message)`

### 5.3 NotesBloc (`lib/features/notes/presentation/bloc/`)
- **Events:**
  - `LoadNotesEvent()`
  - `AddNoteEvent(NoteEntity note)`
  - `UpdateNoteEvent(NoteEntity note)`
  - `DeleteNoteEvent(int noteId)`
  - `TogglePinNoteEvent(int noteId)`
- **States:**
  - `NotesInitial()`
  - `NotesLoading()`
  - `NotesLoaded(List<NoteEntity> notes)`
  - `NotesError(String message)`

### 5.4 PlannerBloc (`lib/features/planner/presentation/bloc/`)
- **Events:**
  - `LoadPlannerItemsEvent(DateTime date)`
  - `AddPlannerItemEvent(PlannerItemEntity item)`
  - `UpdatePlannerItemEvent(PlannerItemEntity item)`
  - `TogglePlannerItemEvent(int itemId, DateTime date)`
  - `DeletePlannerItemEvent(int itemId)`
  - `ClearCompletedPlannerItemsEvent(DateTime date)`
- **States:**
  - `PlannerInitial()`
  - `PlannerLoading()`
  - `PlannerLoaded(List<PlannerItemEntity> items, DateTime selectedDate)`
  - `PlannerError(String message)`

### 5.5 VaultBloc (`lib/features/vault/presentation/bloc/`)
- **Events:**
  - `LoadVaultItemsEvent()`
  - `AddVaultPasswordEvent(VaultItemEntity item)`
  - `DeleteVaultItemEvent(String id)`
- **States:**
  - `VaultInitial()`
  - `VaultLocked()`
  - `VaultLoading()`
  - `VaultLoaded(List<VaultItemEntity> passwords, List<VaultItemEntity> documents)`
  - `VaultError(String message)`

---

## 6. Core Shared Widgets (All 18 Components & Purposes)

Located in `lib/core/widgets/`:

1. **`SafeSpendMeterWidget` (`safe_spend_meter_widget.dart`):**  
   Calculates and visualizes daily discretionary spending limit using formula: `(MonthlyBudget - FixedBills - SpentThisMonth) / DaysRemaining`.
2. **`QuickCaptureSheet` (`quick_capture_sheet.dart`):**  
   Universal bottom modal for 5-second entry of Expenses, Tasks, Quick Notes, or Voice capture.
3. **`AppActionSheet` (`app_action_sheet.dart`):**  
   Standard bottom sheet container with drag handle, animated entrance, and rounded corners.
4. **`HabitBubbleWidget` (`habit_bubble_widget.dart`):**  
   Interactive circular progress indicator for daily habits with streak badge and completion pulse.
5. **`AudioBriefingSheet` (`audio_briefing_sheet.dart`):**  
   Morning briefing synthesis displaying calendar highlights, daily safe spend, and urgent tasks.
6. **`SearchBarWidget` (`search_bar_widget.dart`):**  
   Debounced search input field with clear button and query callback.
7. **`FilterBottomSheet` (`filter_bottom_sheet.dart`):**  
   Multi-category and date-range filter sheet for transactions and notes.
8. **`ChipInputWidget` (`chip_input_widget.dart`):**  
   Interactive tag chip editor allowing dynamic addition and removal of hashtags.
9. **`AppButton` (`app_button.dart`):**  
   Custom primary, secondary, and destructive button with loading spinner state and haptic feedback.
10. **`AppTextField` (`app_text_field.dart`):**  
    Form text input with floating label, validation error display, and custom focus ring.
11. **`AppDropdownMenu` (`app_dropdown_menu.dart`):**  
    Themed selector for categories, payment modes, recurrence types, and priority levels.
12. **`ConfirmationDialog` (`confirmation_dialog.dart`):**  
    Two-button confirmation modal for destructive operations (delete note, clear tasks).
13. **`AppEmptyState` (`app_empty_state.dart`):**  
    Visually pleasing empty illustration with headline, subtext, and call-to-action button.
14. **`AppLoader` (`app_loader.dart`):**  
    Adaptive theme-matching loading spinner.
15. **`AppShimmerLoader` (`app_shimmer_loader.dart`):**  
    Skeleton loading placeholders for list cards while SQLite queries execute.
16. **`PaginatedListView` (`paginated_list_view.dart`):**  
    Scroll controller supporting infinite pagination and pull-to-refresh.
17. **`NetworkAwareWidget` (`network_aware_widget.dart`):**  
    Displays subtle banner when device has no internet connection for synced services.
18. **`ErrorWidget` (`error_widget.dart`):**  
    User-friendly error state with retry button and error details.

---

## 7. Screen-by-Screen Breakdown & UI Interaction Details

### 7.1 Screen 1: Today Hub (`lib/features/today_hub/presentation/pages/today_hub_page.dart`)
- **Header:**
  - Displays user avatar, current date in `EEEE, d MMMM` format, and dynamic greeting (`Good Morning`, `Good Afternoon`, `Good Evening`).
  - Audio Briefing pill button: Opens `AudioBriefingSheet`.
- **Habits Horizontal Reel:**
  - Displays list of `HabitBubbleWidget` items.
  - Tapping a bubble triggers `ToggleHabitEvent`. When completed, plays haptic tick, increments streak, and changes color to vibrant green.
- **Timeline Time-Block Cards:**
  - Chronological schedule of the day.
  - Each card shows start time, task title, category pill, and action button.
  - Tapping the checkmark calls `ToggleTimelineItemEvent` and strikes through text.
- **Empty State:** Shows relaxed illustration if all items are done.

### 7.2 Screen 2: Money Manager (`lib/features/money/presentation/pages/money_manager_page.dart`)
- **Safe-to-Spend Dashboard Card:**
  - Shows Safe Daily Spend amount in large bold font.
  - Gauge indicator showing % of budget used.
  - Monthly budget progress bar: `Spent ₹X of ₹Y`.
- **Tabs (Transactions / Subscriptions / IOUs):**
  - **Transactions Tab:**
    - List of transactions grouped by date.
    - Floating "+" button opens Add Transaction sheet (Amount, Title, Category, Mode).
  - **Subscriptions Tab:**
    - Cards showing recurring service, monthly price, and next renewal date.
    - "Auto-Kill" toggle switch. When turned on, schedules OS notifications 3 days and 1 day prior to billing.
  - **IOUs (Splitwise) Tab:**
    - Net balance bar: Shows whether people owe you or you owe people.
    - Lent / Borrowed cards with "Settle Up" action button.

### 7.3 Screen 3: Notes & Knowledge Base (`lib/features/notes/presentation/pages/notes_page.dart`)
- **Search & Tag Filter Bar:**
  - Instant live filter as user types.
  - Horizontal list of tags (`#all`, `#work`, `#personal`, `#ideas`).
- **Masonry Note Grid:**
  - Pinned notes shelf at the top with pin icon.
  - Note cards with custom pastel card colors and markdown rendering.
- **Full-Screen Note Editor Modal:**
  - Title input, markdown editor body, color picker palette, and tag manager.
  - Auto-saves draft on dismissal or pause in typing.

### 7.4 Screen 4: Planner & Focus Center (`lib/features/planner/presentation/pages/planner_page.dart`)
- **Interactive Calendar Header:**
  - Horizontal week strip with dates. Selecting a day refreshes the agenda.
  - Month/Day toggle.
- **Focus Timer (PomodoroCard):**
  - Circular countdown timer (Focus 25m, Short Break 5m, Long Break 15m).
  - Start, Pause, Reset controls.
  - "Link to Task" button to attribute focus sessions to a specific planner task.
- **Milestone Countdown Card:**
  - Tracks key upcoming deadlines (e.g., "Project Launch: 4 days, 6 hours left").
- **Planner Item List:**
  - Cards show Priority badge (Urgent/High/Medium/Low), Time range, Category icon, and subtask count (`2/4 subtasks`).
  - Expanding card reveals subtask checklist with interactive checkboxes.
  - Swipe-to-delete with confirmation snackbar.

### 7.5 Screen 5: Vault & Security Lock (`lib/features/vault/presentation/pages/vault_page.dart`)
- **Lock Screen Overlay (`vault_lock_screen.dart`):**
  - Appears if vault is locked or app was backgrounded.
  - Biometric scan automatically prompts on display.
  - Fallback 4/6 digit PIN Dialpad with animated dot indicators.
  - Optional 3x3 pattern lock grid.
- **Encrypted Password Manager:**
  - Cards showing account name, username, hidden password with eye toggle.
  - "Copy Password" button that auto-clears clipboard after 30 seconds.

---

## 8. Cross-Module Intelligent Workflows

1. **Quick Capture Voice Parser:**
   - User speaks: *"Paid 350 for groceries with UPI"*
   - System parses: Amount = `350`, Category = `Food & Groceries`, Mode = `UPI`, Type = `expense`.
   - Dispatches `AddTransactionEvent` and shows a confirmation toast.
2. **Safe-Spend Daily Recalculation:**
   - Every time an expense is saved or budget is updated, the safe spend formula recalculates and updates the Today Hub header metric instantly.
3. **Recurring Task Auto-Rollover:**
   - Planner items with `repeatType = 'daily'` or `repeatType = 'weekdays'` automatically appear in future dates without duplicating database rows.
4. **Subscription Auto-Kill Notification Pipeline:**
   - Enabling `autoKillEnabled` calls `NotificationService.scheduleNotification` exactly 72 hours before `renewalDate`, warning the user to cancel before card is charged.

---

## 9. End-to-End Implementation Execution Checklist

| # | System Area | Status | Implementation Action |
|---|---|---|---|
| 1 | **Database (Drift SQLite)** | Complete | Version 2 schema active with all columns. |
| 2 | **Dependency Injection (`sl`)** | Complete | All repositories, use cases, and blocs registered. |
| 3 | **Planner Recurrence Engine** | Complete | Handled in `PlannerItemEntity.isScheduledForDate()`. |
| 4 | **Pomodoro Timer & Countdown** | Complete | Custom timer widget and countdown card integrated. |
| 5 | **Money Manager & Safe Spend** | In Progress | Connect live transaction sum stream to dynamic Safe Spend gauge. |
| 6 | **Subscriptions & IOU Splitwise**| In Progress | Link auto-kill toggle directly to `NotificationService`. |
| 7 | **Today Hub Daily Reset** | In Progress | Implement midnight streak reset check on app launch. |
| 8 | **Notes Live Tag Filter** | In Progress | Wire tag chips directly to BLoC search query filter. |
| 9 | **Vault Biometric & PIN Flow** | In Progress | Wire `SecurityLocalDataSource` to hardware biometric sensor. |
| 10| **Global Navigation Shell** | In Progress | Bind central FAB directly to `QuickCaptureSheet`. |

---

> **Ready for Implementation:** This document is the complete and uncompromised specification of every function, entity, screen, widget, and workflow in Daily Life OS. Awaiting your call to implement!
