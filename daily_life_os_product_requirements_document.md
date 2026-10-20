# Product Requirements Document (PRD): Daily Life OS (All-in-One Flutter App)

**Document Status:** Draft v1.0  
**Platform:** iOS & Android (Built with Flutter)  
**Architecture:** Offline-First with Optional Encrypted Cloud Sync  

---

## 1. Executive Summary & Product Vision

**The Problem:**  
Busy individuals juggle 4 to 6 separate apps every day for reminders, expense tracking, daily notes, habit building, and storing passwords/documents. Switching between apps creates friction, and worse, none of these apps communicate with each other (e.g., a bill reminder doesn't talk to the expense tracker).

**The Solution:**  
**Daily Life OS** is an all-in-one, hyper-connected personal utility application built in Flutter. Instead of acting like five separate apps stuffed into a single menu, it connects **Time (Reminders/Focus)**, **Money (Expenses/Budgets)**, **Mind (Notes/Voice)**, and **Security (Passwords/Document Vault)** through a single **Today Hub** and hands-free **Voice/AI Quick-Capture**.

---

## 2. Core Design Pillars

1. **Zero-Friction Input:** Any expense, reminder, or note must be loggable in under 3 seconds using Voice (Speech-to-Text), Camera OCR, or Natural Language typing.
2. **Cross-Module Intelligence:** Modules must talk to each other (e.g., marking a bill reminder "Done" automatically logs the expense; saving a gadget expense prompts to save the warranty receipt).
3. **Hands-Free & Proactive:** Talking Notifications (Text-to-Speech) and Morning Audio Briefings help users stay on track while driving, cooking, or walking.
4. **Offline-First & Private:** 100% functional without internet, with hardware-backed biometric encryption for sensitive passwords and documents.

---

## 3. Information Architecture & 5-Tab Navigation

The application is structured around a 5-tab bottom navigation bar with a persistent floating **Quick-Capture Bar** on the Home screen.

```
[1. Today Hub]   [2. Planner & Focus]   [3. Money Manager]   [4. Notes & Ideas]   [5. Secure Vault]
                       ▲
         (Floating Voice / Quick-Capture Bar)
```

---

## 4. Detailed Feature Specifications by Module

### Module 1: Today Hub (Home Screen Command Center)
The single scrollable dashboard showing only what matters right now.
* **Live Header & "Play My Day" (TTS):** Displays date, greeting, and a `[🔊 Play Briefing]` button that uses Text-to-Speech to read out today's top tasks, birthdays, and remaining daily safe-to-spend budget.
* **Chronological Timeline Feed:** Shows today's upcoming reminders, bill due dates, and important events sorted by time.
* **Habit & Micro-Routine Strip:** Horizontal row of one-tap bubbles (e.g., *Drink 3L Water*, *Vitamins*, *Read 15 mins*) with streak counters.
* **Daily Spend Meter:** A sleek progress bar showing *Today's Spend vs. Safe Daily Limit* (calculated dynamically from the monthly budget).
* **Floating Quick-Capture Bar:** Fixed above the bottom nav with `[🎤 Hold to Speak]`, `[⌨️ Quick Type]`, and `[📷 Scan Bill/Text]`.
* **60-Second Evening Wrap-Up:** Triggered at 9:30 PM to review unchecked habits, log missed cash expenses, and roll unfinished tasks to tomorrow.

### Module 2: Planner, Focus & Smart Reminders
Time management, alarms, and deep work tools.
* **Talking Reminders (TTS Alerts):** Custom voice announcements when a reminder triggers (e.g., *"Hey, it's 5 PM. Time to call the bank."*), with an automatic toggle to mute voice when the phone is in Silent/DND mode.
* **Actionable Lock-Screen Notifications:** Notification banners include interactive buttons: `[Mark Done]`, `[Snooze +15m]`, and `[Log Payment]` (for bill reminders).
* **Natural Language Date Parsing:** Typing *"Doctor appointment tomorrow at 4pm"* automatically sets the date and time.
* **Location & Wi-Fi Triggers:** Set reminders triggered by arriving/leaving a location or connecting to Home/Office Wi-Fi.
* **Focus Timer (Pomodoro):** 25/5 minute work/break timer linked to specific tasks, with a pinned Live Notification on the lock screen.
* **Important Dates & Countdowns:** Tracks birthdays, anniversaries, and custom events with advance notifications (e.g., 7 days and 1 day prior) and links to gift/planning notes.

### Module 3: Money Manager (Expenses, Budgets & Bills)
Complete daily financial control without spreadsheet complexity.
* **Quick Expense Logger:** 2-tap category logging (Food, Travel, Bills, Shopping, Health, etc.) with payment mode tags (UPI, Cash, Card).
* **Monthly Budget & Category Cost Limits:** Set an overall monthly budget and specific category caps. Automatically fires **80% Warning** and **100% Limit Reached** notifications.
* **Dynamic "Safe-to-Spend" Calculator:** Automatically calculates how much money the user can safely spend today using the formula:
  $$\text{Daily Safe Spend} = \frac{\text{Monthly Budget} - (\text{Fixed Bills} + \text{Spent So Far})}{\text{Days Remaining in Month}}$$
* **Subscription & Recurring Bill Tracker:** Tracks monthly/yearly renewals with "Auto-Kill" alerts 2 days before renewal so users can cancel unused subscriptions.
* **Lend & Borrow (IOU) Mini-Ledger:** Tracks money lent to or borrowed from friends, linked with one-tap payment reminders.
* **Auto-UPI / SMS Notification Catcher (Android) & Screenshot Parser:** Reads incoming payment alerts or shared screenshots of UPI receipts to pre-fill the amount and merchant name automatically.

### Module 4: Notes, Voice Memos & Lists
Fast brain-dumping and organized knowledge capture.
* **Daily Scratchpad:** Instant, zero-setup top pad for quick numbers or temporary thoughts.
* **Dual Voice-to-Text Notes (STT):** Recording a voice note simultaneously generates a live text transcript so users can either read or listen back later.
* **Task & Expense Converter:** Highlight any line in a note or checklist to convert it directly into a **Planner Reminder** or **Expense Entry**.
* **Context Bundling ("Going Out" Tags):** Tag notes, checklists, and reminders with `@Market` or `@Office` to view them together on a single screen.
* **Camera OCR Text Grabber:** Scan physical bills, whiteboards, or book pages directly into editable note text.

### Module 5: Secure Vault (Passwords & Warranty Locker)
Hardware-encrypted storage protected by Biometrics (Fingerprint / FaceID).
* **Password & PIN Manager:** Stores website logins, bank PINs, Wi-Fi passwords, and secure notes using AES-256 encryption.
* **Decoy / "Panic" PIN Mode:** Supports a secondary PIN that opens a clean, decoy vault if the user is forced to unlock the app in front of someone else.
* **Warranty & Document Locker:** Stores photos/PDFs of gadget receipts, medical prescriptions, ID cards, and vehicle insurance.
* **Automated Expiry Alerts:** Extracts or logs warranty/insurance expiry dates and automatically schedules reminders 30 days and 7 days before expiration.

---

## 5. Cross-Module Smart Workflows (The "Secret Sauce")

| Trigger Action | Automated Cross-Module Result |
| :--- | :--- |
| **Voice Input:** *"Spent 450 on electricity bill"* | 1. Logs ₹450 under *Bills* in **Money Manager**.<br>2. Marks this month's *Electricity Bill Reminder* as **Done** in **Planner**. |
| **Voice Input:** *"Remind me to buy a charger tomorrow at 6 PM"* | Creates a scheduled notification in **Planner** with **Text-to-Speech** enabled. |
| **Logging a Gadget Expense** (e.g., ₹2,000 Earphones) | Prompts a 1-tap button: *"Snap photo of bill & set 1-year warranty reminder in Vault?"* |
| **Birthday Reminder Triggers** | Notification includes a direct link to the user's *"Gift Ideas"* checklist in **Notes**. |

---

## 6. Technical Stack & Flutter Packages

### Architecture & State Management
* **Framework:** Flutter (Dart 3.x)
* **State Management:** `flutter_bloc` (Clean Architecture with modular feature folders)
* **Navigation:** `go_router`

### Local Databases & Security
* **Structured Data (Notes, Expenses, Tasks, Habits):** `isar` or `drift` (SQLite) for ultra-fast offline queries and filtering.
* **Encrypted Vault Storage:** `flutter_secure_storage` (Keychain on iOS, Keystore on Android) + `encrypt` (AES-256 for vault files).
* **Biometric Authentication:** `local_auth` (Fingerprint & FaceID).

### Smart Features (Voice, AI, Notifications & OS Integration)
* **Text-to-Speech (Talking Reminders & Briefings):** `flutter_tts`
* **Speech-to-Text (Voice Quick-Capture & Notes):** `speech_to_text` + `record`
* **Local Notifications & Alarms:** `flutter_local_notifications` + `timezone` + `android_alarm_manager_plus`
* **OCR & Receipt Scanning:** `google_mlkit_text_recognition` + `image_picker`
* **Natural Language & On-Device AI Parsing:** Custom Regex date/amount parser + optional `google_generative_ai` integration.
* **Home Screen Widgets & Shake Trigger:** `home_widget` + `sensors_plus` + `share_plus`

---

## 7. Phased Development Roadmap (MVP to v3.0)

### Phase 1: Core MVP (Weeks 1–4)
* Setup Flutter project architecture, local database (`Drift`/`Isar`), and 5-tab navigation shell.
* Build **Today Hub** layout and basic **Quick-Capture Text Bar**.
* Build **Planner (Reminders + Habits)** with local notifications.
* Build **Money Manager** (Expense logging + Monthly Budget + Safe-to-Spend meter).
* Build **Notes** (Text notes + checklists).

### Phase 2: Voice, Security & Cross-Linking (Weeks 5–7)
* Integrate `speech_to_text` for **Voice Quick-Capture** and smart intent parsing (auto-sorting voice into Expense, Reminder, or Note).
* Integrate `flutter_tts` for **Talking Reminders** and the **Morning Audio Briefing**.
* Build the **Secure Vault** with `local_auth` biometric lock, Password Manager, and **Warranty Locker**.
* Connect cross-module workflows (Bill Reminder $\rightarrow$ Expense Logger).

### Phase 3: Next-Gen Polish & Automation (Weeks 8–10)
* Add **Camera OCR Scanner** for receipts and notes (`google_mlkit_text_recognition`).
* Add **Home Screen Widgets** and **Screenshot-to-Action** sharing.
* Add **AI Weekly Pattern Coach** and **60-Second Evening Wrap-Up**.
* Optional encrypted cloud backup (Google Drive / Firebase).

---

## 8. Success Metrics (KPIs)
* **Speed to Log:** Average time to record a new expense, note, or reminder is **< 4 seconds**.
* **Daily Retention:** % of users who interact with the **Today Hub** at least twice a day (Morning Briefing & Evening Wrap-Up).
* **Cross-Feature Adoption:** % of users actively using at least 3 of the 5 modules every week.


use sqlite for database (using drift).  
use flutter_bloc for state management.
