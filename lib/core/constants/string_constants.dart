class StringConstants {
  StringConstants._();

  // App Identity
  static const String appName = 'Daily Life OS';
  static const String appTagline = 'Time • Money • Mind • Security in One Flow';
  static const String appVersion = '1.0.0';

  // Navigation (5 Core Modules)
  static const String navToday = 'Today Hub';
  static const String navPlanner = 'Planner';
  static const String navMoney = 'Money';
  static const String navNotes = 'Notes';
  static const String navVault = 'Vault';

  // Floating Quick-Capture Bar
  static const String holdToSpeak = 'Hold to Speak';
  static const String quickType = 'Quick Type';
  static const String scanText = 'Scan Bill/Text';
  static const String quickCaptureTitle = 'Zero-Friction Capture';
  static const String quickCaptureHint =
      'e.g. "Spent 450 on electricity bill" or "Call bank tomorrow 5pm"';

  // Module 1: Today Hub
  static const String playBriefing = 'Play Briefing';
  static const String playingAudio = 'Playing Audio Briefing...';
  static const String audioBriefSectionTitle = "Today's Audio Brief";
  static const String audioBriefSectionSubtitle =
      'Tap to hear a clear summary of today\'s habits, schedule, tasks & safe spend.';
  static const String audioBriefingSheetTitle = 'Daily Audio Briefing';
  static const String audioBriefingSheetSubtitle =
      'Complete summary of all your activities for today';
  static const String audioBriefTapSectionHint =
      'Tap any activity section below to hear it spoken aloud';
  static const String audioBriefPlayAll = 'Play Full Brief';
  static const String audioBriefOverviewTitle = 'Daily Momentum & Overview';
  static const String audioBriefHabitsTitle = 'Habits & Micro-Routines';
  static const String audioBriefScheduleTitle = "Today's Schedule & Tasks";
  static const String audioBriefMoneyTitle = 'Safe-to-Spend & Money Pulse';
  static const String audioBriefStatusPlaying = 'Speaking Briefing';
  static const String audioBriefStatusPaused = 'Briefing Paused';
  static const String audioBriefStatusReady = 'Ready to Play';
  static const String timelineFeed = "Today's Timeline";
  static const String habitsAndRoutines = 'Habits & Micro-Routines';
  static const String dailySpendMeter = 'Daily Safe-to-Spend';
  static const String eveningWrapUpTitle = '60-Second Evening Wrap-Up';
  static const String eveningWrapUpSubtitle =
      'Review habits, log cash & roll unfinished items to tomorrow.';
  static const String eveningWrapUpAction = 'Start Wrap-Up';

  // Module 2: Planner & Focus
  static const String smartReminders = 'Smart Reminders';
  static const String setReminder = 'Set Reminder';
  static const String reminderHint = 'What do you need to be reminded of?';
  static const String focusTimer = 'Focus Timer (Pomodoro)';
  static const String workSprint = 'Work Sprint';
  static const String shortBreak = 'Short Break';
  static const String startTimer = 'Start Focus';
  static const String pauseTimer = 'Pause';
  static const String resetTimer = 'Reset';
  static const String countdowns = 'Important Dates & Countdowns';
  static const String talkingReminder = 'Talking Reminder (TTS)';
  static const String markDone = 'Mark Done';
  static const String snooze15m = 'Snooze +15m';

  // Module 3: Money Manager
  static const String safeToSpendToday = 'Safe-to-Spend Today';
  static const String monthlyBudget = 'Monthly Budget';
  static const String spentSoFar = 'Spent So Far';
  static const String remainingBudget = 'Remaining';
  static const String quickExpense = 'Quick Expense';
  static const String subscriptions = 'Subscriptions & Auto-Kill';
  static const String lendAndBorrow = 'Lend & Borrow (IOU)';
  static const String amountLabel = 'Amount';
  static const String categoryLabel = 'Category';
  static const String paymentModeLabel = 'Payment Mode';
  static const String paymentModeUPI = 'UPI';
  static const String paymentModeCash = 'Cash';
  static const String paymentModeCard = 'Card';
  static const String budgetAlert80 = '80% Budget limit reached';
  static const String budgetLimit100 = 'Monthly budget reached!';

  // Money — Navigation (dedicated Money bottom bar)
  static const String moneyNavOverview = 'Overview';
  static const String moneyNavActivity = 'Activity';
  static const String moneyNavAdd = 'Add';
  static const String moneyNavBudgets = 'Budgets';
  static const String moneyNavInsights = 'Insights';

  // Money — Overview
  static const String totalBalance = 'Total Balance';
  static const String mainAccount = 'Main Account';
  static const String balanceTrend = '14-Day Balance Trend';
  static const String quickCategoryLogging = 'Quick Category Logging';
  static const String recentTransactions = 'Recent Transactions';
  static const String monthlyBudgets = 'Monthly Budgets';
  static const String moneyTools = 'Money Tools';
  static const String seeAll = 'See all';
  static const String thisMonth = 'This Month';
  static const String income = 'Income';
  static const String expense = 'Expense';
  static const String expenses = 'Expenses';
  static const String reports = 'Reports';
  static const String transfer = 'Transfer';
  static const String noTransactionsTitle = 'No transactions yet';
  static const String noTransactionsMessage =
      'Tap + to log your first expense or income.';

  // Money — Add / Edit Transaction
  static const String addExpense = 'Add Expense';
  static const String addIncome = 'Add Income';
  static const String editTransaction = 'Edit Transaction';
  static const String merchantLabel = 'Merchant / Payee';
  static const String merchantHint = 'e.g. Big Bazaar, Uber, Salary';
  static const String incomeSourceLabel = 'Source';
  static const String incomeSourceHint = 'e.g. Salary, Freelance project';
  static const String dateLabel = 'Date';
  static const String detailsLabel = 'Details';
  static const String noteLabel = 'Note (optional)';
  static const String noteHint = 'Add a note about this transaction...';
  static const String selectCategoryError = 'Please select a category';
  static const String expenseAdded = 'Expense Added!';
  static const String incomeAdded = 'Income Added!';
  static const String transactionUpdated = 'Transaction updated';
  static const String transactionDeleted = 'Transaction deleted';
  static const String addAnother = 'Add Another';
  static const String deleteTransactionTitle = 'Delete transaction?';
  static const String deleteTransactionMessage =
      'This transaction will be permanently removed.';

  // Money — Activity
  static const String searchTransactions = 'Search transactions...';
  static const String allTypes = 'All';
  static const String filterByCategory = 'Category';
  static const String noMatchingTransactions = 'No matching transactions';
  static const String noMatchingTransactionsMessage =
      'Try a different search or clear the filters.';

  // Money — Budgets
  static const String budgetManager = 'Budgets';
  static const String categoryLimits = 'Category Limits';
  static const String tapToEdit = 'Tap to edit';
  static const String spent = 'Spent';
  static const String remaining = 'Remaining';
  static const String categoriesOk = 'Categories OK';
  static const String onTrack = 'On track';
  static const String nearLimit = 'Near limit';
  static const String overBudget = 'Over budget';
  static const String noLimitSet = 'No limit set';
  static const String monthlyLimit = 'Monthly Limit';
  static const String saveLimit = 'Save Limit';
  static const String currentSpend = 'Current spend';
  static const String budgetTips = 'Budget Tips';
  static const String budgetTipRuleTitle = '50/30/20 Rule';
  static const String budgetTipRuleBody = 'Needs 50%, Wants 30%, Savings 20%';
  static const String budgetTipWeeklyTitle = 'Track Weekly';
  static const String budgetTipWeeklyBody =
      'Review spending every week to stay on track';
  static const String budgetTipBufferTitle = 'Buffer Zone';
  static const String budgetTipBufferBody =
      'Set limits 10–15% below your actual max';
  static const String gotIt = 'Got it';
  static const String safeSpendSettings = 'Safe-to-Spend Settings';
  static const String fixedBills = 'Fixed Bills';

  // Money — Insights
  static const String analytics = 'Analytics';
  static const String selectMonth = 'Select Month';
  static const String thisWeek = 'This week';
  static const String lastWeek = 'Last week';
  static const String previousMonth = 'Previous month';
  static const String vsAverage = 'vs avg';
  static const String totalAssets = 'Total Assets';
  static const String netCashflow = 'Net Cashflow';
  static const String byCategory = 'By Category';
  static const String monthlySpending = 'Monthly Spending';
  static const String topCategories = 'Top Spending Categories';
  static const String transactionsLabel = 'Transactions';
  static const String avgPerDay = 'Avg / Day';
  static const String budgetScore = 'Budget Score';
  static const String saved = 'saved';

  // Money — Tools (Subscriptions, IOU, Accounts, Settings)
  static const String subscriptionsShort = 'Subscriptions';
  static const String lendBorrowShort = 'Lend & Borrow';
  static const String accounts = 'Accounts';
  static const String moneySettings = 'Money Settings';
  static const String addSubscription = 'Add Subscription';
  static const String addIou = 'Add IOU';
  static const String addAccount = 'Add Account';
  static const String editAccount = 'Edit Account';
  static const String personLabel = 'Person';
  static const String lent = 'Lent';
  static const String borrowed = 'Borrowed';
  static const String settle = 'Settle';
  static const String renewalDateLabel = 'Renewal Date';
  static const String autoKillLabel = 'Auto-Kill reminder';
  static const String accountName = 'Account Name';
  static const String accountType = 'Account Type';
  static const String balanceLabel = 'Balance';
  static const String cash = 'Cash';
  static const String savings = 'Savings';
  static const String investments = 'Investments';
  static const String currencyLabel = 'Currency';
  static const String budgetAlertsLabel = 'Budget Alerts';
  static const String budgetAlertsSubtitle =
      'Notify me at 80% and 100% of a category limit';
  static const String moneyLockLabel = 'Lock Money with Vault Security';
  static const String moneyLockSubtitle =
      'Require PIN / pattern / biometrics to open Money';
  static const String moneyLocked = 'Money is Locked';

  // Module 4: Notes & Ideas
  static const String dailyScratchpad = 'Daily Scratchpad';
  static const String scratchpadHint =
      'Instant brain dump, phone numbers, quick thoughts...';
  static const String voiceNotes = 'Voice-to-Text Memos';
  static const String contextBundling = 'Context Bundling';
  static const String tagMarket = '@Market';
  static const String tagOffice = '@Office';
  static const String tagHome = '@Home';
  static const String convertToReminder = 'Convert to Reminder';
  static const String convertToExpense = 'Convert to Expense';

  // Module 5: Secure Vault
  static const String secureVaultTitle = 'Hardware-Encrypted Vault';
  static const String unlockWithBiometrics = 'Unlock with Biometrics';
  static const String vaultLocked = 'Vault is Locked';
  static const String passwordManager = 'Passwords & PINs';
  static const String warrantyLocker = 'Warranty & Document Locker';
  static const String decoyMode = 'Decoy / Panic PIN Mode';
  static const String decoyModeActive = 'Decoy Mode Active';
  static const String expiryAlerts = 'Automated Expiry Alerts';
  static const String expiringInDays = 'Expires in';

  // Common Actions & Feedback
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String done = 'Done';
  static const String add = 'Add';
  static const String retry = 'Retry';
  static const String viewAll = 'View All';
  static const String search = 'Search anything...';
  static const String comingSoon = 'Coming Soon';
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError =
      'No internet connection. Please check your network.';

  // General Dashboard Keys
  static const String quickActions = 'Quick Actions';
  static const String activeHabits = 'Active Habits';
  static const String upcomingTasks = 'Upcoming Tasks';

  // Universal Command Palette & Spotlight Search
  static const String commandPaletteTitle = 'Universal Command & Search';
  static const String commandPaletteHint =
      'Search habits, tasks, notes, expenses, logins, or run a command...';
  static const String spotlightSearchTooltip = 'Universal Search & Commands';
  static const String quickLaunchDockTitle = 'OS Quick Launch';
  static const String commandPaletteEmptyTitle =
      'No matching items or commands';
  static const String commandPaletteEmptySubtitle =
      'Try another keyword or tap Quick Capture to create it.';
  static const String commandPaletteShortcutPrefix = '⌘K';
  static const String commandPaletteIndexedSuffix = 'indexed';

  // Quick Launch Dock Pills
  static const String dockSpotlightTitle = '⌘K Search';
  static const String dockSpotlightSubtitle = 'All 5 modules';
  static const String dockFocusTitle = 'Focus Sprint';
  static const String dockFocusSubtitle = 'Pomodoro & Zen';
  static const String dockCaptureTitle = 'Quick Add';
  static const String dockCaptureSubtitle = 'Smart NLP input';
  static const String dockNotesTitle = 'Scratchpad';
  static const String dockNotesSubtitle = 'Notes & checklists';

  // Bottom Navigation Labels
  static const String navTodayTab = 'Today';
  static const String viewAction = 'View';

  // Data / Failure Messages
  static const String saveFailed =
      'Could not save. Please check storage space and try again.';
  static const String loadFailed = 'Could not load your data.';
  static const String invalidAmount = 'Enter an amount greater than zero.';
  static const String partialIndexWarning =
      "Some modules couldn't be searched right now";

  // Quick Capture
  static const String quickCaptureSavedPrefix = 'Saved:';
  static const String quickCaptureSaving = 'Saving...';
  static const String quickCaptureDefaultIncome = 'Quick Income';
  static const String quickCaptureDefaultExpense = 'Quick Expense';
  static const String quickCaptureDefaultReminder = 'Quick Reminder';
  static const String quickCaptureDefaultHabit = 'Daily Micro-Routine';
  static const String quickCaptureDefaultNote = 'Quick Voice / Text Note';
  static const String quickCaptureHabitDescription =
      'Created via Quick Capture';
  static const String quickCaptureModuleLabel =
      'SAVE TO MODULE (AUTO-DETECTED OR TAP TO CHANGE)';
  static const String intentLabelExpense = 'Money / Expense';
  static const String intentLabelReminder = 'Planner / Reminder';
  static const String intentLabelHabit = 'Today / Habit';
  static const String intentLabelNote = 'Notes / Idea';

  // Security / Lock Screen
  static const String incorrectPin = 'Incorrect PIN. Try again.';
  static const String incorrectPinPrefix = 'Incorrect PIN.';
  static const String incorrectPattern = 'Pattern does not match. Try again.';
  static const String incorrectPatternPrefix = 'Incorrect pattern.';
  static const String biometricUnlockReason =
      'Scan your fingerprint to unlock Secure Vault';
  static const String lockoutMessagePrefix =
      'Too many failed attempts. Locked for';
  static const String securityCooldownTitle = 'Security Cooldown Active';
  static const String securityCooldownSubtitle =
      'Rate-limit triggered. Inputs paused for safety.';
  static const String secureVaultLockedTitle = 'Secure Vault Locked';
  static const String secureVaultLockedSubtitle =
      'Hardware AES-256 encrypted storage';
  static const String lockoutSecondsCaption =
      'Seconds remaining until unlock is re-enabled';
  static const String pinCodeTab = 'PIN Code';
  static const String patternLockTab = 'Pattern Lock';
  static const String autoLockFooter = 'Auto-locks when app is backgrounded';

  // Profile & OS Control Center
  static const String profileTitle = 'Profile & OS Preferences';
  static const String profileSubtitle =
      'Personalize your identity, workspace modules & quick controls';
  static const String profileTooltip = 'Open Profile & OS Preferences';
  static const String editProfileIdentity = 'Edit Name & Bio';
  static const String displayNameLabel = 'Your Display Name';
  static const String displayNameHint = 'Enter your name (e.g., Aarav)';
  static const String taglineLabel = 'Personal Tagline / Role';
  static const String taglineHint = 'e.g., Focused Builder • Daily Life OS';
  static const String avatarSectionTitle = 'Profile Picture & Avatar Style';
  static const String pickFromGallery = 'Gallery Photo';
  static const String takeCameraPhoto = 'Camera';
  static const String removePhoto = 'Use Avatar Style';
  static const String workspaceControlsSection =
      'Workspace & Quick-Access Controls';
  static const String quickAccessBallTitle = 'Floating Quick-Access Ball';
  static const String quickAccessBallSubtitle =
      'Show movable quick-capture ball across screens for instant voice & text entry';
  static const String quickLaunchDockToggleTitle = 'OS Quick-Launch Dock';
  static const String quickLaunchDockToggleSubtitle =
      'Show ⌘K Search, Focus Sprint, Quick Add & Scratchpad bar on Today Hub';
  static const String audioBriefBannerToggleTitle =
      "Today's Audio Brief Banner";
  static const String audioBriefBannerToggleSubtitle =
      'Show interactive voice briefing card on the Today Hub dashboard';
  static const String safeSpendBannerToggleTitle = 'Daily Safe-to-Spend Meter';
  static const String safeSpendBannerToggleSubtitle =
      'Display live daily budget allowance and spend progress on Today Hub';
  static const String eveningWrapUpToggleTitle = '60-Second Evening Wrap-Up';
  static const String eveningWrapUpToggleSubtitle =
      'Show end-of-day reflection and task rollover card on Today Hub';
  static const String voiceAndSystemSection =
      'Voice, Appearance & Regional Settings';
  static const String autoPlayBriefingTitle = 'Auto-Speak Audio Briefing';
  static const String autoPlayBriefingSubtitle =
      'Automatically start voice playback when opening the Daily Audio Briefing';
  static const String hapticFeedbackTitle = 'Tactile Haptic Feedback';
  static const String hapticFeedbackSubtitle =
      'Subtle vibration feedback when toggling habits, tasks, and quick actions';
  static const String appearanceModeTitle = 'App Appearance';
  static const String themeSystem = 'System';
  static const String themeLight = 'Light';
  static const String themeDark = 'Dark';
  static const String activeCurrencyTitle = 'Primary Currency';
  static const String dailyFocusGoalTitle = 'Daily Deep-Work Target';
  static const String resetDefaultsLabel = 'Reset OS Preferences to Default';
  static const String profileSavedMessage = 'Profile updated';

  // Money Power Workflows (Transfer, Subscription Pay, IOU Sync, Statement)
  static const String transferBetweenAccounts = 'Transfer Between Accounts';
  static const String transferFromLabel = 'From Account';
  static const String transferToLabel = 'To Account';
  static const String transferSuccessMessage = 'Funds transferred successfully';
  static const String transferSameAccountError =
      'Source and destination accounts must be different';
  static const String transferInsufficientAccounts =
      'Add at least 2 accounts to transfer funds';
  static const String payAndAdvanceLabel = 'Pay & Advance';
  static const String subscriptionPaymentLogged =
      'Subscription payment logged & next renewal advanced';
  static const String iouSettledWithCashflow = 'IOU settled & cashflow updated';
  static const String financialStatementTitle = 'Financial Statement & Report';
  static const String financialStatementSubtitle =
      'Summary of cashflow, safe-to-spend, budgets & account balances';
  static const String copyStatementLabel = 'Copy Statement';
  static const String statementCopiedMessage =
      'Financial statement copied to clipboard';

  // Cross-Module Smart Actions & Vault Pulse
  static const String convertedToReminderMessage = 'Saved to Planner Reminders';
  static const String convertedToExpenseMessage = 'Logged to Money Expenses';
  static const String pushToTodayTimeline = "Add to Today's Timeline";
  static const String pushedToTimelineMessage = "Added to Today's Timeline";
  static const String vaultSecurityPulseTitle = 'Vault Security & Expiry Pulse';
  static const String vaultHealthyLabel = 'All Vault items healthy';
  static const String vaultWeakPasswordsLabel = 'Weak Passwords';
  static const String vaultExpiringDocsLabel = 'Expiring / Expired';

  // Next-Wave Enhancements (CSV Export, Repeat Today, Bill Split, OS Backup)
  static const String exportCsvTooltip = 'Export CSV to Clipboard';
  static const String csvExportedMessage =
      'Transactions exported as CSV to clipboard';
  static const String repeatTodayLabel = 'Repeat Today';
  static const String repeatedTodayMessage = 'Logged a copy for today';
  static const String billSplitTitle = 'Smart Bill Split & IOU Calculator';
  static const String billSplitSubtitle =
      'Split bills with friends, log your share & auto-create collection IOUs';
  static const String billSplitShort = 'Bill Split';
  static const String billSplitLogAction = 'Log My Share & Create IOUs';
  static const String billSplitSuccessMessage =
      'Your share logged & friend IOUs created';
  static const String workspaceBackupSectionTitle =
      'Workspace Data & Backup Summary';
  static const String copyWorkspaceBackupLabel = 'Copy Full OS Backup Summary';
  static const String workspaceBackupCopiedMessage =
      'Workspace backup summary copied to clipboard';
}
