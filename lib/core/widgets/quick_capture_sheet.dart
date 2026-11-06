import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../../di/injection_container.dart';
import '../../features/today_hub/domain/entities/habit_entity.dart';
import '../../features/today_hub/domain/usecases/manage_habits_usecase.dart';
import '../constants/string_constants.dart';
import '../database/app_database.dart';
import '../notifications/notification_service.dart';

enum QuickCaptureMode { text, voice, scan }

enum DetectedIntent { expense, reminder, habit, note }

/// Result returned when QuickCaptureSheet logs an item so the caller
/// can refresh state and optionally jump to the target tab.
class QuickCaptureResult {
  final DetectedIntent intent;
  final String summary;
  final int targetTabIndex; // 0: Today, 1: Planner, 2: Money, 3: Notes

  const QuickCaptureResult({
    required this.intent,
    required this.summary,
    required this.targetTabIndex,
  });
}

class QuickCaptureSheet extends StatefulWidget {
  final QuickCaptureMode initialMode;

  const QuickCaptureSheet({
    super.key,
    this.initialMode = QuickCaptureMode.text,
  });

  static Future<QuickCaptureResult?> show(
    BuildContext context, {
    QuickCaptureMode mode = QuickCaptureMode.text,
  }) {
    return showModalBottomSheet<QuickCaptureResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickCaptureSheet(initialMode: mode),
    );
  }

  @override
  State<QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends State<QuickCaptureSheet> {
  late QuickCaptureMode _mode;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(
    text: '450',
  );

  bool _isRecording = false;
  int _voiceWaveStep = 0;

  // Smart intent & manual override
  DetectedIntent _detectedIntent = DetectedIntent.reminder;
  DetectedIntent? _manualIntentOverride;

  // Configurable Expense / Money fields
  bool _isIncome = false;
  String _expenseCategory = 'bills';
  String _paymentMode = 'UPI';

  // Configurable Reminder / Planner fields
  bool _isTomorrow = false;
  String _reminderTime = '05:00 PM';
  String _reminderPriority = 'medium';
  String _reminderCategory = 'Personal';

  // Configurable Habit fields
  String _habitCategory = 'Health';

  // Configurable Note fields
  String _noteTag = '@QuickCapture';
  bool _pinNote = false;

  // Selected Scan Preset Index
  int _selectedScanPreset = 0;

  static const List<({String label, String transcript, String hint})>
  _voiceSamplePhrases = [
    (
      label: '🎙️ "Spent ₹450 on electricity bill"',
      transcript: 'Spent ₹450 on electricity bill via UPI',
      hint: 'Auto-detects ₹450 Expense • Bills • UPI',
    ),
    (
      label: '🎙️ "Call bank tomorrow at 5 PM urgent"',
      transcript: 'Call bank tomorrow at 5:00 PM urgent',
      hint: 'Auto-detects Reminder • Tomorrow 05:00 PM • Urgent',
    ),
    (
      label: '🎙️ "Daily habit Drink 3L water"',
      transcript: 'Daily habit Drink 3L water and electrolytes',
      hint: 'Auto-detects Today Habit • Health',
    ),
    (
      label: '🎙️ "Idea: Launch Q4 product roadmap @Office"',
      transcript: 'Note idea: Launch Q4 product roadmap @Office',
      hint: 'Auto-detects Note • @Office tag',
    ),
  ];

  static const List<
    ({
      String title,
      String subtitle,
      IconData icon,
      String extractedText,
      DetectedIntent intent,
      String amount,
      String category,
      String mode,
    })
  >
  _scanTemplates = [
    (
      title: 'Electricity Bill',
      subtitle: '₹1,240 • Utility Receipt',
      icon: Icons.bolt_rounded,
      extractedText: 'Paid ₹1240 State Electricity Bill receipt',
      intent: DetectedIntent.expense,
      amount: '1240',
      category: 'bills',
      mode: 'UPI',
    ),
    (
      title: 'Grocery Receipt',
      subtitle: '₹865 • Supermarket',
      icon: Icons.shopping_bag_rounded,
      extractedText: 'Spent ₹865 at FreshMart Grocery Store',
      intent: DetectedIntent.expense,
      amount: '865',
      category: 'food',
      mode: 'Card',
    ),
    (
      title: 'Cab Invoice',
      subtitle: '₹520 • Transit Bill',
      icon: Icons.local_taxi_rounded,
      extractedText: 'Paid ₹520 for Uber airport ride',
      intent: DetectedIntent.expense,
      amount: '520',
      category: 'transport',
      mode: 'UPI',
    ),
    (
      title: 'Action Item',
      subtitle: 'Whiteboard / Task',
      icon: Icons.task_alt_rounded,
      extractedText:
          'Remind to submit Q4 architecture spec tomorrow at 10:00 AM',
      intent: DetectedIntent.reminder,
      amount: '0',
      category: 'Work',
      mode: 'UPI',
    ),
    (
      title: 'Book Highlight',
      subtitle: 'Study / Page OCR',
      icon: Icons.menu_book_rounded,
      extractedText:
          'Atomic Habits takeaway: 1% daily improvements compound @Office',
      intent: DetectedIntent.note,
      amount: '0',
      category: 'Personal',
      mode: 'UPI',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    if (_mode == QuickCaptureMode.voice) {
      _isRecording = true;
      _voiceWaveStep = 1;
    } else if (_mode == QuickCaptureMode.scan) {
      _applyScanTemplate(0);
    }

    _textController.addListener(_parseIntentFromText);
  }

  @override
  void dispose() {
    _textController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _applyScanTemplate(int index) {
    final tpl = _scanTemplates[index];
    setState(() {
      _selectedScanPreset = index;
      _manualIntentOverride = tpl.intent;
      _detectedIntent = tpl.intent;
      if (tpl.amount != '0') {
        _amountController.text = tpl.amount;
      }
      if (tpl.intent == DetectedIntent.expense) {
        _expenseCategory = tpl.category;
        _paymentMode = tpl.mode;
        _isIncome = false;
      } else if (tpl.intent == DetectedIntent.reminder) {
        _reminderCategory = tpl.category;
      }
      _textController.text = tpl.extractedText;
    });
  }

  void _parseIntentFromText() {
    final raw = _textController.text;
    final text = raw.toLowerCase();

    // 1. Extract amount if present
    final numMatch =
        RegExp(
          r'(?:₹|rs\.?\s*|spent\s+|paid\s+|earned\s+|cost\s+|bill\s+)(\d+(?:\.\d+)?)',
          caseSensitive: false,
        ).firstMatch(raw) ??
        RegExp(r'\b(\d{2,6}(?:\.\d{1,2})?)\b').firstMatch(raw);

    if (numMatch != null) {
      final parsedAmt = numMatch.group(1);
      if (parsedAmt != null && parsedAmt.isNotEmpty) {
        _amountController.text = parsedAmt;
      }
    }

    // 2. Extract time if present (e.g., "5pm", "5:30 pm", "10 am")
    final timeMatch = RegExp(
      r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
      caseSensitive: false,
    ).firstMatch(raw);
    if (timeMatch != null) {
      final hr = int.tryParse(timeMatch.group(1)!) ?? 5;
      final min = timeMatch.group(2) ?? '00';
      final mer = timeMatch.group(3)!.toUpperCase();
      _reminderTime = '${hr.toString().padLeft(2, '0')}:$min $mer';
    }

    // 3. Extract date ("tomorrow" vs "today")
    if (text.contains('tomorrow') || text.contains('tmrw')) {
      _isTomorrow = true;
    } else if (text.contains('today')) {
      _isTomorrow = false;
    }

    // 4. Extract priority
    if (text.contains('urgent') || text.contains('asap')) {
      _reminderPriority = 'urgent';
    } else if (text.contains('high') || text.contains('important')) {
      _reminderPriority = 'high';
    }

    // 5. Extract expense category & payment mode
    if (text.contains('earned') ||
        text.contains('salary') ||
        text.contains('income') ||
        text.contains('received')) {
      _isIncome = true;
    } else if (text.contains('spent') ||
        text.contains('paid') ||
        text.contains('bought')) {
      _isIncome = false;
    }

    if (text.contains('bill') ||
        text.contains('electr') ||
        text.contains('wifi') ||
        text.contains('rent')) {
      _expenseCategory = 'bills';
    } else if (text.contains('food') ||
        text.contains('coffee') ||
        text.contains('lunch') ||
        text.contains('dinner') ||
        text.contains('grocery')) {
      _expenseCategory = 'food';
    } else if (text.contains('cab') ||
        text.contains('uber') ||
        text.contains('metro') ||
        text.contains('fuel') ||
        text.contains('taxi')) {
      _expenseCategory = 'transport';
    } else if (text.contains('shop') ||
        text.contains('amazon') ||
        text.contains('charger')) {
      _expenseCategory = 'shopping';
    }

    if (text.contains('cash')) {
      _paymentMode = 'Cash';
    } else if (text.contains('card') || text.contains('credit')) {
      _paymentMode = 'Card';
    } else if (text.contains('upi') || text.contains('gpay')) {
      _paymentMode = 'UPI';
    }

    // 6. Extract Note tags
    if (text.contains('@market')) {
      _noteTag = '@Market';
    } else if (text.contains('@office') || text.contains('@work')) {
      _noteTag = '@Office';
    } else if (text.contains('@home')) {
      _noteTag = '@Home';
    } else if (text.contains('password') ||
        text.contains('pin') ||
        text.contains('secret') ||
        text.contains('warranty')) {
      _noteTag = '@Vault';
    }

    // 7. Determine primary intent (unless manually overridden by user)
    DetectedIntent autoIntent;
    if (text.contains('spent') ||
        text.contains('paid') ||
        text.contains('bought') ||
        text.contains('earned') ||
        text.contains('salary') ||
        text.contains('rs') ||
        text.contains('₹') ||
        text.contains('bill') ||
        text.contains('cost')) {
      autoIntent = DetectedIntent.expense;
    } else if (text.contains('habit') ||
        text.contains('routine') ||
        text.contains('every day') ||
        text.contains('daily')) {
      autoIntent = DetectedIntent.habit;
    } else if (text.contains('note') ||
        text.contains('idea') ||
        text.contains('@market') ||
        text.contains('@office') ||
        text.contains('@home') ||
        text.contains('password') ||
        text.contains('secret')) {
      autoIntent = DetectedIntent.note;
    } else if (text.contains('remind') ||
        text.contains('at ') ||
        text.contains('tomorrow') ||
        text.contains('pm') ||
        text.contains('am') ||
        text.contains('call') ||
        text.contains('meeting') ||
        text.contains('task')) {
      autoIntent = DetectedIntent.reminder;
    } else {
      autoIntent = _manualIntentOverride ?? DetectedIntent.reminder;
    }

    setState(() {
      _detectedIntent = _manualIntentOverride ?? autoIntent;
    });
  }

  String _cleanTitleText(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return switch (_detectedIntent) {
        DetectedIntent.expense =>
          _isIncome
              ? 'Quick Income'
              : 'Quick Expense (${_expenseCategory.toUpperCase()})',
        DetectedIntent.reminder => 'Quick Reminder',
        DetectedIntent.habit => 'Daily Micro-Routine',
        DetectedIntent.note => 'Quick Voice / Text Note',
      };
    }
    return trimmed;
  }

  Future<void> _submitQuickCapture(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final effectiveText = _cleanTitleText(_textController.text);
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final todayIso = nowIso.substring(0, 10);
    final tomorrowIso = now
        .add(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    int targetTabIndex = 0;
    String summaryText = effectiveText;

    if (sl.isRegistered<AppDatabase>()) {
      try {
        final db = sl<AppDatabase>();

        switch (_detectedIntent) {
          case DetectedIntent.expense:
            final parsedAmount =
                double.tryParse(_amountController.text.trim()) ?? 250.0;
            final amount = parsedAmount <= 0 ? 250.0 : parsedAmount;
            await db
                .into(db.transactions)
                .insert(
                  TransactionsCompanion.insert(
                    title: effectiveText,
                    category: _expenseCategory,
                    amount: amount,
                    mode: _paymentMode,
                    iconCodePoint: _isIncome
                        ? Icons.south_west_rounded.codePoint
                        : Icons.bolt_rounded.codePoint,
                    date: nowIso,
                    type: Value(_isIncome ? 'income' : 'expense'),
                    note: Value('Captured via ${_mode.name.toUpperCase()}'),
                  ),
                );
            targetTabIndex = 2; // Money tab
            summaryText =
                '${_isIncome ? "Income" : "Expense"} ₹${amount.toStringAsFixed(0)} ($effectiveText)';
            break;

          case DetectedIntent.reminder:
            final targetDate = _isTomorrow ? tomorrowIso : todayIso;
            await db
                .into(db.plannerItems)
                .insert(
                  PlannerItemsCompanion.insert(
                    title: effectiveText,
                    date: targetDate,
                    startTime: Value(_reminderTime),
                    category: _reminderCategory,
                    priority: Value(_reminderPriority),
                    colorValue: AppColors.moduleTime.toARGB32(),
                    iconCodePoint: Icons.notifications_active_rounded.codePoint,
                    notes: Value('Captured via ${_mode.name.toUpperCase()}'),
                  ),
                );
            if (!_isTomorrow) {
              await db
                  .into(db.timelineItems)
                  .insert(
                    TimelineItemsCompanion.insert(
                      time: _reminderTime,
                      title: effectiveText,
                      category: _reminderCategory,
                      colorValue: AppColors.moduleTime.toARGB32(),
                      iconCodePoint:
                          Icons.notifications_active_rounded.codePoint,
                      action: 'Start',
                      date: todayIso,
                    ),
                  );
            }
            if (sl.isRegistered<NotificationService>()) {
              final scheduledTime = now.add(const Duration(hours: 1));
              await sl<NotificationService>().scheduleNotification(
                id: effectiveText.hashCode & 0x7FFFFFFF,
                title: 'Reminder: $effectiveText',
                body: 'Scheduled for $_reminderTime ($_reminderCategory)',
                scheduledDate: scheduledTime,
              );
            }
            targetTabIndex = 1; // Planner tab
            summaryText =
                '"$effectiveText" (${_isTomorrow ? "Tomorrow" : "Today"} at $_reminderTime)';
            break;

          case DetectedIntent.habit:
            if (sl.isRegistered<AddHabitUseCase>()) {
              await sl<AddHabitUseCase>()(
                HabitEntity(
                  id: 0,
                  title: effectiveText,
                  description: 'Created via Quick Capture',
                  iconCodePoint: Icons.bolt_rounded.codePoint,
                  colorValue: AppColors.primary.toARGB32(),
                  streakDays: 0,
                  isDoneToday: false,
                  createdAt: nowIso,
                  category: _habitCategory,
                  scheduleType: 'daily',
                ),
              );
            } else {
              await db
                  .into(db.habits)
                  .insert(
                    HabitsCompanion.insert(
                      title: effectiveText,
                      iconCodePoint: Icons.bolt_rounded.codePoint,
                      colorValue: AppColors.primary.toARGB32(),
                      createdAt: nowIso,
                    ),
                  );
            }
            targetTabIndex = 0; // Today Hub tab
            summaryText = 'Habit "$effectiveText" ($_habitCategory)';
            break;

          case DetectedIntent.note:
            await db
                .into(db.notes)
                .insert(
                  NotesCompanion.insert(
                    title: effectiveText.length > 48
                        ? '${effectiveText.substring(0, 48)}...'
                        : effectiveText,
                    content: effectiveText,
                    colorValue: AppColors.moduleNotes.toARGB32(),
                    isPinned: Value(_pinNote),
                    tags: Value(_noteTag),
                    createdAt: nowIso,
                    updatedAt: nowIso,
                  ),
                );
            targetTabIndex = 3; // Notes tab
            summaryText = 'Note "$effectiveText" ($_noteTag)';
            break;
        }
      } catch (_) {}
    }

    if (context.mounted) {
      Navigator.of(context).pop(
        QuickCaptureResult(
          intent: _detectedIntent,
          summary: summaryText,
          targetTabIndex: targetTabIndex,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.textHeading;
    final captionColor = isDark
        ? AppColors.darkTextCaption
        : AppColors.textCaption;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBackground : Colors.white,
              borderRadius: AppRadius.topXxl,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: dividerColor,
                      borderRadius: AppRadius.radiusFull,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Header with Title, Active Intent Badge & 3 Mode Tabs
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            StringConstants.quickCaptureTitle,
                            style: AppTextStyles.titleLarge.copyWith(
                              color: headingColor,
                              fontSize: 17,
                            ),
                          ),
                          _buildIntentBadge(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModeTab(
                          Icons.keyboard_rounded,
                          'Type',
                          QuickCaptureMode.text,
                          isDark,
                        ),
                        const SizedBox(width: 6),
                        _buildModeTab(
                          Icons.mic_rounded,
                          'Speak',
                          QuickCaptureMode.voice,
                          isDark,
                        ),
                        const SizedBox(width: 6),
                        _buildModeTab(
                          Icons.document_scanner_rounded,
                          'Scan',
                          QuickCaptureMode.scan,
                          isDark,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Dynamic Body based on Mode
                AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_mode == QuickCaptureMode.voice) ...[
                        _buildVoiceRecordingView(
                          isDark,
                          headingColor,
                          captionColor,
                        ),
                        const SizedBox(height: 10),
                      ] else if (_mode == QuickCaptureMode.scan) ...[
                        _buildScanView(
                          isDark,
                          headingColor,
                          captionColor,
                          dividerColor,
                        ),
                        const SizedBox(height: 10),
                      ],
                      // Always show the editable text box so Voice transcripts & OCR scans
                      // can be inspected and refined immediately!
                      _buildTextInputView(isDark, headingColor, captionColor),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Target Module Selector Pills (Auto-detected + Manual Override)
                Text(
                  'SAVE TO MODULE (AUTO-DETECTED OR TAP TO CHANGE)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: captionColor,
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: DetectedIntent.values.map((intent) {
                      final selected = _detectedIntent == intent;
                      final color = _intentColor(intent);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          selected: selected,
                          showCheckmark: false,
                          avatar: Icon(
                            _intentIcon(intent),
                            size: 14,
                            color: selected ? Colors.white : color,
                          ),
                          label: Text(_intentLabel(intent)),
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : headingColor,
                          ),
                          selectedColor: color,
                          backgroundColor: isDark
                              ? AppColors.darkSurfaceSecondary
                              : AppColors.surfaceSecondary,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _manualIntentOverride = intent;
                              _detectedIntent = intent;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),

                // Context-Aware Smart Parameter Editor Strip
                _buildSmartParametersCard(
                  isDark: isDark,
                  headingColor: headingColor,
                  captionColor: captionColor,
                  dividerColor: dividerColor,
                ),
                const SizedBox(height: 12),

                // Quick Suggestion Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickChip('Spent ₹450 Electricity', isDark, () {
                        _manualIntentOverride = null;
                        _textController.text = 'Spent ₹450 on electricity bill';
                      }),
                      AppSpacing.gapW8,
                      _buildQuickChip('Call Bank Tomorrow 5PM', isDark, () {
                        _manualIntentOverride = null;
                        _textController.text = 'Call bank tomorrow at 5pm';
                      }),
                      AppSpacing.gapW8,
                      _buildQuickChip('Daily Habit: Read 20m', isDark, () {
                        _manualIntentOverride = null;
                        _textController.text =
                            'Daily habit Read 20 mins before bed';
                      }),
                      AppSpacing.gapW8,
                      _buildQuickChip('Buy charger @Market', isDark, () {
                        _manualIntentOverride = null;
                        _textController.text = 'Buy phone charger @Market';
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Save / Execute Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _submitQuickCapture(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _intentColor(_detectedIntent),
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.radiusMd,
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.bolt_rounded),
                    label: Text(
                      'Log to ${_intentLabel(_detectedIntent)} (Instant)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextInputView(
    bool isDark,
    Color headingColor,
    Color captionColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceSecondary
            : AppColors.surfaceSecondary,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: TextField(
        controller: _textController,
        autofocus: _mode == QuickCaptureMode.text,
        maxLines: 2,
        minLines: 1,
        style: TextStyle(color: headingColor, fontSize: 14.5),
        decoration: InputDecoration(
          hintText: StringConstants.quickCaptureHint,
          hintStyle: TextStyle(color: captionColor, fontSize: 13),
          prefixIcon: Icon(
            _mode == QuickCaptureMode.voice
                ? Icons.record_voice_over_rounded
                : (_mode == QuickCaptureMode.scan
                      ? Icons.document_scanner_rounded
                      : Icons.edit_note_rounded),
            size: 18,
            color: _intentColor(_detectedIntent),
          ),
          suffixIcon: _textController.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear text',
                  onPressed: () {
                    setState(() {
                      _manualIntentOverride = null;
                      _textController.clear();
                    });
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: captionColor,
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildVoiceRecordingView(
    bool isDark,
    Color headingColor,
    Color captionColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.voiceWaveform.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: AppColors.voiceWaveform.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Interactive Mic Toggle Button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _isRecording = !_isRecording;
                    _voiceWaveStep++;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? AppColors.voiceWaveform
                        : AppColors.voiceWaveform.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    boxShadow: _isRecording
                        ? [
                            BoxShadow(
                              color: AppColors.voiceWaveform.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _isRecording ? Icons.mic_rounded : Icons.mic_off_rounded,
                    color: _isRecording
                        ? Colors.white
                        : AppColors.voiceWaveform,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isRecording
                          ? 'Listening... Tap a voice phrase or dictate below'
                          : 'Voice capture paused — Tap mic to resume',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.voiceWaveform,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Deterministic animated waveform bars (settles cleanly in tests)
                    Row(
                      children: List.generate(14, (index) {
                        final activeHeight = _isRecording
                            ? 8.0 +
                                  ((index * 7 + _voiceWaveStep * 5) % 18)
                                      .toDouble()
                            : 5.0;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.only(right: 3),
                          width: 3.5,
                          height: activeHeight,
                          decoration: BoxDecoration(
                            color: AppColors.voiceWaveform.withValues(
                              alpha: _isRecording ? 0.9 : 0.35,
                            ),
                            borderRadius: AppRadius.radiusFull,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Interactive Voice Phrases to simulate instant speech-to-intent
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _voiceSamplePhrases.map((phrase) {
              return ActionChip(
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: isDark
                    ? AppColors.darkCardBackground
                    : Colors.white,
                side: BorderSide(
                  color: AppColors.voiceWaveform.withValues(alpha: 0.3),
                ),
                label: Text(
                  phrase.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: headingColor,
                  ),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _manualIntentOverride = null;
                    _voiceWaveStep++;
                    _textController.text = phrase.transcript;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScanView(
    bool isDark,
    Color headingColor,
    Color captionColor,
    Color dividerColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.moduleMoney.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: AppColors.moduleMoney.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.moduleMoney.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  size: 20,
                  color: AppColors.moduleMoney,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Camera OCR Text & Bill Grabber',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.moduleMoney,
                      ),
                    ),
                    Text(
                      'Select a receipt/document scan preset or edit OCR text below',
                      style: TextStyle(fontSize: 11, color: captionColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_scanTemplates.length, (index) {
                final tpl = _scanTemplates[index];
                final isSelected = _selectedScanPreset == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _applyScanTemplate(index);
                    },
                    borderRadius: AppRadius.radiusMd,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.moduleMoney
                            : (isDark
                                  ? AppColors.darkCardBackground
                                  : Colors.white),
                        borderRadius: AppRadius.radiusMd,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.moduleMoney
                              : dividerColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tpl.icon,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : AppColors.moduleMoney,
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tpl.title,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : headingColor,
                                ),
                              ),
                              Text(
                                tpl.subtitle,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : captionColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartParametersCard({
    required bool isDark,
    required Color headingColor,
    required Color captionColor,
    required Color dividerColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceSecondary
            : AppColors.surfaceSecondary,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: dividerColor, width: 0.8),
      ),
      child: switch (_detectedIntent) {
        DetectedIntent.expense => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Expense vs Income toggle
                ChoiceChip(
                  label: const Text('Expense'),
                  selected: !_isIncome,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (_) => setState(() => _isIncome = false),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Income'),
                  selected: _isIncome,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (_) => setState(() => _isIncome = true),
                ),
                const SizedBox(width: 10),
                // Editable Amount Input
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: headingColor,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixText: '₹ ',
                        labelText: 'Amount',
                        labelStyle: TextStyle(
                          fontSize: 11,
                          color: captionColor,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final mode in ['UPI', 'Card', 'Cash'])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(mode),
                        selected: _paymentMode == mode,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelStyle: const TextStyle(fontSize: 11),
                        onSelected: (_) => setState(() => _paymentMode = mode),
                      ),
                    ),
                  Container(
                    width: 1,
                    height: 18,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: dividerColor,
                  ),
                  for (final cat in [
                    'bills',
                    'food',
                    'transport',
                    'shopping',
                    'other',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(cat[0].toUpperCase() + cat.substring(1)),
                        selected: _expenseCategory == cat,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelStyle: const TextStyle(fontSize: 11),
                        onSelected: (_) =>
                            setState(() => _expenseCategory = cat),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        DetectedIntent.reminder => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Today'),
                selected: !_isTomorrow,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelStyle: const TextStyle(fontSize: 11),
                onSelected: (_) => setState(() => _isTomorrow = false),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Tomorrow'),
                selected: _isTomorrow,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelStyle: const TextStyle(fontSize: 11),
                onSelected: (_) => setState(() => _isTomorrow = true),
              ),
              const SizedBox(width: 8),
              for (final t in ['09:00 AM', '01:00 PM', '05:00 PM', '08:00 PM'])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(t),
                    selected: _reminderTime == t,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelStyle: const TextStyle(fontSize: 11),
                    onSelected: (_) => setState(() => _reminderTime = t),
                  ),
                ),
              for (final p in ['medium', 'high', 'urgent'])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(p.toUpperCase()),
                    selected: _reminderPriority == p,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelStyle: const TextStyle(fontSize: 10.5),
                    onSelected: (_) => setState(() => _reminderPriority = p),
                  ),
                ),
            ],
          ),
        ),
        DetectedIntent.habit => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text(
                'Habit Category:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: captionColor,
                ),
              ),
              const SizedBox(width: 8),
              for (final cat in [
                'Health',
                'Mindfulness',
                'Learning',
                'Fitness',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: _habitCategory == cat,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelStyle: const TextStyle(fontSize: 11),
                    onSelected: (_) => setState(() => _habitCategory = cat),
                  ),
                ),
            ],
          ),
        ),
        DetectedIntent.note => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('Pin Note'),
                selected: _pinNote,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelStyle: const TextStyle(fontSize: 11),
                onSelected: (v) => setState(() => _pinNote = v),
              ),
              const SizedBox(width: 8),
              for (final tag in [
                '@QuickCapture',
                '@Office',
                '@Market',
                '@Home',
                '@Vault',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(tag),
                    selected: _noteTag == tag,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelStyle: const TextStyle(fontSize: 11),
                    onSelected: (_) => setState(() => _noteTag = tag),
                  ),
                ),
            ],
          ),
        ),
      },
    );
  }

  Widget _buildIntentBadge() {
    final color = _intentColor(_detectedIntent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadius.radiusSm,
      ),
      child: Text(
        _intentLabel(_detectedIntent),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildModeTab(
    IconData icon,
    String label,
    QuickCaptureMode mode,
    bool isDark,
  ) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _mode = mode;
          _isRecording = mode == QuickCaptureMode.voice;
          if (mode == QuickCaptureMode.scan &&
              _textController.text.trim().isEmpty) {
            _applyScanTemplate(_selectedScanPreset);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark
                    ? AppColors.darkSurfaceSecondary
                    : AppColors.surfaceSecondary),
          borderRadius: AppRadius.radiusMd,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppColors.iconColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextBody : AppColors.textBody),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceSecondary
              : AppColors.surfaceSecondary,
          borderRadius: AppRadius.radiusFull,
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextBody : AppColors.textBody,
          ),
        ),
      ),
    );
  }

  Color _intentColor(DetectedIntent intent) {
    switch (intent) {
      case DetectedIntent.expense:
        return AppColors.moduleMoney;
      case DetectedIntent.reminder:
        return AppColors.moduleTime;
      case DetectedIntent.habit:
        return AppColors.primary;
      case DetectedIntent.note:
        return AppColors.moduleNotes;
    }
  }

  IconData _intentIcon(DetectedIntent intent) {
    switch (intent) {
      case DetectedIntent.expense:
        return Icons.account_balance_wallet_rounded;
      case DetectedIntent.reminder:
        return Icons.notifications_active_rounded;
      case DetectedIntent.habit:
        return Icons.repeat_rounded;
      case DetectedIntent.note:
        return Icons.lightbulb_rounded;
    }
  }

  String _intentLabel(DetectedIntent intent) {
    switch (intent) {
      case DetectedIntent.expense:
        return 'Money / Expense';
      case DetectedIntent.reminder:
        return 'Planner / Reminder';
      case DetectedIntent.habit:
        return 'Today / Habit';
      case DetectedIntent.note:
        return 'Notes / Idea';
    }
  }
}
