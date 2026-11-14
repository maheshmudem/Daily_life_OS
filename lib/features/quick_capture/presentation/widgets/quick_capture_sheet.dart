import 'dart:async';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/widgets/bloc_effect_listener.dart';
import '../../../../di/injection_container.dart';
import '../../domain/entities/quick_capture_entities.dart';
import '../bloc/quick_capture_bloc.dart';

export '../../domain/entities/quick_capture_entities.dart';

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
      backgroundColor: AppColors.transparent,
      builder: (ctx) => QuickCaptureSheet(initialMode: mode),
    );
  }

  @override
  State<QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends State<QuickCaptureSheet> {
  late QuickCaptureMode _mode;
  late final QuickCaptureBloc _bloc;
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
    _bloc = sl<QuickCaptureBloc>();
    _mode = widget.initialMode;
    if (_mode == QuickCaptureMode.voice) {
      _isRecording = true;
      _voiceWaveStep = 1;
    } else if (_mode == QuickCaptureMode.scan) {
      _applyScanTemplate(0);
    }

    _textController.addListener(_dispatchParseIntent);
  }

  @override
  void dispose() {
    _textController.dispose();
    _amountController.dispose();
    _bloc.close();
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

  void _dispatchParseIntent() {
    _bloc.add(
      ParseQuickCaptureText(
        _textController.text,
        manualOverride: _manualIntentOverride,
      ),
    );
  }

  void _applyParsedIntent(ParsedQuickCaptureIntentEntity parsed) {
    setState(() {
      if (parsed.extractedAmount != null) {
        _amountController.text = parsed.extractedAmount!;
      }
      if (parsed.extractedTime != null) {
        _reminderTime = parsed.extractedTime!;
      }
      if (parsed.isTomorrow != null) {
        _isTomorrow = parsed.isTomorrow!;
      }
      if (parsed.reminderPriority != null) {
        _reminderPriority = parsed.reminderPriority!;
      }
      if (parsed.isIncome != null) {
        _isIncome = parsed.isIncome!;
      }
      if (parsed.expenseCategory != null) {
        _expenseCategory = parsed.expenseCategory!;
      }
      if (parsed.paymentMode != null) {
        _paymentMode = parsed.paymentMode!;
      }
      if (parsed.noteTag != null) {
        _noteTag = parsed.noteTag!;
      }
      _detectedIntent = _manualIntentOverride ?? parsed.detectedIntent;
    });
  }

  Future<void> _submitQuickCapture(BuildContext context) async {
    unawaited(HapticFeedback.mediumImpact());
    final submission = QuickCaptureSubmissionEntity(
      mode: _mode,
      intent: _detectedIntent,
      rawText: _textController.text,
      amountText: _amountController.text,
      isIncome: _isIncome,
      expenseCategory: _expenseCategory,
      paymentMode: _paymentMode,
      isTomorrow: _isTomorrow,
      reminderTime: _reminderTime,
      reminderPriority: _reminderPriority,
      reminderCategory: _reminderCategory,
      habitCategory: _habitCategory,
      noteTag: _noteTag,
      pinNote: _pinNote,
    );
    _bloc.add(SubmitQuickCapture(submission));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = palette.isDark;
    final headingColor = palette.heading;
    final captionColor = palette.caption;
    final dividerColor = palette.divider;

    return BlocProvider<QuickCaptureBloc>.value(
      value: _bloc,
      child: BlocEffectListener<QuickCaptureEffect>(
        effects: _bloc.effects,
        listener: (context, effect) {
          switch (effect) {
            case QuickCaptureSubmitted(:final result):
              Navigator.of(context).pop(result);
          }
        },
        child: BlocListener<QuickCaptureBloc, QuickCaptureState>(
          listenWhen: (previous, current) =>
              previous.parsedIntent != current.parsedIntent &&
              current.parsedIntent != null,
          listener: (context, state) => _applyParsedIntent(state.parsedIntent!),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageGutter,
                    AppSpacing.sm + AppSpacing.xxxs,
                    AppSpacing.pageGutter,
                    AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: palette.card,
                    borderRadius: AppRadius.topXxl,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor.withValues(alpha: 0.35),
                        blurRadius: AppSpacing.xxl,
                        offset: const Offset(0, -AppSpacing.xxs),
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
                          width: AppSpacing.xxl + AppSpacing.xxs,
                          height: AppSpacing.xxs,
                          decoration: BoxDecoration(
                            color: dividerColor,
                            borderRadius: AppRadius.radiusFull,
                          ),
                        ),
                      ),
                      AppSpacing.gapH12,

                      // Header with Title, Active Intent Badge & 3 Mode Tabs
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xxs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                AppText.titleLarge(
                                  StringConstants.quickCaptureTitle,
                                  color: headingColor,
                                ),
                                _buildIntentBadge(),
                              ],
                            ),
                          ),
                          AppSpacing.gapW8,
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildModeTab(
                                Icons.keyboard_rounded,
                                'Type',
                                QuickCaptureMode.text,
                                isDark,
                              ),
                              const SizedBox(width: AppSpacing.xxs + 2),
                              _buildModeTab(
                                Icons.mic_rounded,
                                'Speak',
                                QuickCaptureMode.voice,
                                isDark,
                              ),
                              const SizedBox(width: AppSpacing.xxs + 2),
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
                      AppSpacing.gapH12,

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
                              AppSpacing.gapH8,
                            ] else if (_mode == QuickCaptureMode.scan) ...[
                              _buildScanView(
                                isDark,
                                headingColor,
                                captionColor,
                                dividerColor,
                              ),
                              AppSpacing.gapH8,
                            ],
                            _buildTextInputView(
                              isDark,
                              headingColor,
                              captionColor,
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapH12,

                      // Target Module Selector Pills
                      AppText.overline(
                        StringConstants.quickCaptureModuleLabel,
                        fontWeight: FontWeight.w800,
                        color: captionColor,
                      ),
                      AppSpacing.gapH8,
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: DetectedIntent.values.map((intent) {
                            final selected = _detectedIntent == intent;
                            final color = _intentColor(intent);
                            return Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.xs,
                              ),
                              child: ChoiceChip(
                                selected: selected,
                                showCheckmark: false,
                                avatar: Icon(
                                  _intentIcon(intent),
                                  size: AppSpacing.sm + AppSpacing.xxxs,
                                  color: selected ? AppColors.textWhite : color,
                                ),
                                label: AppText(_intentLabel(intent)),
                                labelStyle: context.text.captionBold.copyWith(
                                  color: selected
                                      ? AppColors.textWhite
                                      : headingColor,
                                ),
                                selectedColor: color,
                                backgroundColor: palette.surfaceMuted,
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
                      AppSpacing.gapH8,

                      // Context-Aware Smart Parameter Editor Strip
                      _buildSmartParametersCard(
                        isDark: isDark,
                        headingColor: headingColor,
                        captionColor: captionColor,
                        dividerColor: dividerColor,
                      ),
                      AppSpacing.gapH12,

                      // Quick Suggestion Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildQuickChip(
                              'Spent ₹450 Electricity',
                              isDark,
                              () {
                                _manualIntentOverride = null;
                                _textController.text =
                                    'Spent ₹450 on electricity bill';
                              },
                            ),
                            AppSpacing.gapW8,
                            _buildQuickChip(
                              'Call Bank Tomorrow 5PM',
                              isDark,
                              () {
                                _manualIntentOverride = null;
                                _textController.text =
                                    'Call bank tomorrow at 5pm';
                              },
                            ),
                            AppSpacing.gapW8,
                            _buildQuickChip(
                              'Daily Habit: Read 20m',
                              isDark,
                              () {
                                _manualIntentOverride = null;
                                _textController.text =
                                    'Daily habit Read 20 mins before bed';
                              },
                            ),
                            AppSpacing.gapW8,
                            _buildQuickChip('Buy charger @Market', isDark, () {
                              _manualIntentOverride = null;
                              _textController.text =
                                  'Buy phone charger @Market';
                            }),
                          ],
                        ),
                      ),
                      AppSpacing.gapH12,

                      // Save / Execute Button (+ inline failure message)
                      BlocBuilder<QuickCaptureBloc, QuickCaptureState>(
                        buildWhen: (previous, current) =>
                            previous.submitStatus != current.submitStatus ||
                            previous.failure != current.failure,
                        builder: (context, captureState) {
                          final failure = captureState.failure;
                          final isSubmitting = captureState.isSubmitting;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (failure != null) ...[
                                Row(
                                  key: const ValueKey('quick_capture_error'),
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      size: AppSpacing.md,
                                      color: AppColors.error,
                                    ),
                                    AppSpacing.gapW8,
                                    Expanded(
                                      child: AppText.bodySmall(
                                        failure.message,
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                AppSpacing.gapH8,
                              ],
                              SizedBox(
                                height: AppSpacing.huge,
                                child: ElevatedButton.icon(
                                  onPressed: isSubmitting
                                      ? null
                                      : () => _submitQuickCapture(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _intentColor(
                                      _detectedIntent,
                                    ),
                                    foregroundColor: AppColors.textWhite,
                                    disabledBackgroundColor: _intentColor(
                                      _detectedIntent,
                                    ).withValues(alpha: 0.6),
                                    disabledForegroundColor:
                                        AppColors.textWhite,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: AppRadius.radiusMd,
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: isSubmitting
                                      ? const SizedBox.square(
                                          dimension: AppSpacing.md,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.textWhite,
                                          ),
                                        )
                                      : const Icon(Icons.bolt_rounded),
                                  label: AppText.titleSmall(
                                    'Log to ${_intentLabel(_detectedIntent)} (Instant)',
                                    color: AppColors.textWhite,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
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
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: palette.border),
      ),
      child: TextField(
        controller: _textController,
        autofocus: _mode == QuickCaptureMode.text,
        maxLines: 2,
        minLines: 1,
        style: context.text.bodyMedium?.copyWith(color: headingColor),
        decoration: InputDecoration(
          hintText: StringConstants.quickCaptureHint,
          hintStyle: context.text.bodySmall?.copyWith(color: captionColor),
          prefixIcon: Icon(
            _mode == QuickCaptureMode.voice
                ? Icons.record_voice_over_rounded
                : (_mode == QuickCaptureMode.scan
                      ? Icons.document_scanner_rounded
                      : Icons.edit_note_rounded),
            size: AppSpacing.lg - AppSpacing.xxxs,
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
                    size: AppSpacing.md,
                    color: captionColor,
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + AppSpacing.xxxs,
            vertical: AppSpacing.sm,
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
      padding: AppSpacing.edgeInsetsAllSm,
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
                  width: AppSpacing.xxxl + AppSpacing.xxs,
                  height: AppSpacing.xxxl + AppSpacing.xxs,
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
                              blurRadius: AppSpacing.sm,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _isRecording ? Icons.mic_rounded : Icons.mic_off_rounded,
                    color: _isRecording
                        ? AppColors.textWhite
                        : AppColors.voiceWaveform,
                    size: AppSpacing.lg + AppSpacing.xxxs,
                  ),
                ),
              ),
              AppSpacing.gapW12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodySmall(
                      _isRecording
                          ? 'Listening... Tap a voice phrase or dictate below'
                          : 'Voice capture paused — Tap mic to resume',
                      fontWeight: FontWeight.w700,
                      color: AppColors.voiceWaveform,
                    ),
                    AppSpacing.gapH4,
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
          AppSpacing.gapH8,
          Wrap(
            spacing: AppSpacing.xxs + AppSpacing.xxxs,
            runSpacing: AppSpacing.xxs + AppSpacing.xxxs,
            children: _voiceSamplePhrases.map((phrase) {
              return ActionChip(
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: context.palette.card,
                side: BorderSide(
                  color: AppColors.voiceWaveform.withValues(alpha: 0.3),
                ),
                label: AppText.labelSmall(phrase.label, color: headingColor),
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
      padding: AppSpacing.edgeInsetsAllSm,
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
                width: AppSpacing.xxl + AppSpacing.xs,
                height: AppSpacing.xxl + AppSpacing.xs,
                decoration: BoxDecoration(
                  color: AppColors.moduleMoney.withValues(alpha: 0.18),
                  borderRadius: AppRadius.borderSm,
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  size: AppSpacing.lg,
                  color: AppColors.moduleMoney,
                ),
              ),
              AppSpacing.gapW8,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText.titleSmall(
                      'Camera OCR Text & Bill Grabber',
                      fontWeight: FontWeight.w800,
                      color: AppColors.moduleMoney,
                    ),
                    AppText.labelSmall(
                      'Select a receipt/document scan preset or edit OCR text below',
                      color: captionColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapH8,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_scanTemplates.length, (index) {
                final tpl = _scanTemplates[index];
                final isSelected = _selectedScanPreset == index;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _applyScanTemplate(index);
                    },
                    borderRadius: AppRadius.radiusMd,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs + AppSpacing.xxxs,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.moduleMoney
                            : context.palette.card,
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
                            size: AppSpacing.md,
                            color: isSelected
                                ? AppColors.textWhite
                                : AppColors.moduleMoney,
                          ),
                          const SizedBox(width: AppSpacing.xxs + 2),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText.captionBold(
                                tpl.title,
                                color: isSelected
                                    ? AppColors.textWhite
                                    : headingColor,
                              ),
                              AppText.labelSmall(
                                tpl.subtitle,
                                color: isSelected
                                    ? AppColors.textWhite.withValues(
                                        alpha: 0.85,
                                      )
                                    : captionColor,
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
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + AppSpacing.xxxs,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: dividerColor, width: 0.8),
      ),
      child: switch (_detectedIntent) {
        DetectedIntent.expense => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ChoiceChip(
                  label: const AppText('Expense'),
                  selected: !_isIncome,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (_) => setState(() => _isIncome = false),
                ),
                const SizedBox(width: AppSpacing.xxs + 2),
                ChoiceChip(
                  label: const AppText('Income'),
                  selected: _isIncome,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (_) => setState(() => _isIncome = true),
                ),
                AppSpacing.gapW8,
                Expanded(
                  child: SizedBox(
                    height: AppSpacing.xxl,
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: context.text.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: headingColor,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixText: '₹ ',
                        labelText: 'Amount',
                        labelStyle: context.text.labelSmall?.copyWith(
                          color: captionColor,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xxs + AppSpacing.xxxs,
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: AppRadius.borderSm,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.gapH8,
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final mode in ['UPI', 'Card', 'Cash'])
                    Padding(
                      padding: const EdgeInsets.only(
                        right: AppSpacing.xxs + AppSpacing.xxxs,
                      ),
                      child: ChoiceChip(
                        label: AppText(mode),
                        selected: _paymentMode == mode,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelStyle: context.text.labelSmall,
                        onSelected: (_) => setState(() => _paymentMode = mode),
                      ),
                    ),
                  Container(
                    width: 1,
                    height: AppSpacing.md + AppSpacing.xxxs,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxs,
                    ),
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
                      padding: const EdgeInsets.only(
                        right: AppSpacing.xxs + AppSpacing.xxxs,
                      ),
                      child: ChoiceChip(
                        label: AppText(cat[0].toUpperCase() + cat.substring(1)),
                        selected: _expenseCategory == cat,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelStyle: context.text.labelSmall,
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
                label: const AppText('Today'),
                selected: !_isTomorrow,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelStyle: context.text.labelSmall,
                onSelected: (_) => setState(() => _isTomorrow = false),
              ),
              const SizedBox(width: AppSpacing.xxs + 2),
              ChoiceChip(
                label: const AppText('Tomorrow'),
                selected: _isTomorrow,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelStyle: context.text.labelSmall,
                onSelected: (_) => setState(() => _isTomorrow = true),
              ),
              AppSpacing.gapW8,
              for (final t in ['09:00 AM', '01:00 PM', '05:00 PM', '08:00 PM'])
                Padding(
                  padding: const EdgeInsets.only(
                    right: AppSpacing.xxs + AppSpacing.xxxs,
                  ),
                  child: ChoiceChip(
                    label: AppText(t),
                    selected: _reminderTime == t,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelStyle: context.text.labelSmall,
                    onSelected: (_) => setState(() => _reminderTime = t),
                  ),
                ),
              for (final p in ['medium', 'high', 'urgent'])
                Padding(
                  padding: const EdgeInsets.only(
                    right: AppSpacing.xxs + AppSpacing.xxxs,
                  ),
                  child: ChoiceChip(
                    label: AppText(p.toUpperCase()),
                    selected: _reminderPriority == p,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelStyle: context.text.labelSmall,
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
              AppText.labelSmall(
                'Habit Category:',
                fontWeight: FontWeight.w700,
                color: captionColor,
              ),
              AppSpacing.gapW8,
              for (final cat in [
                'Health',
                'Mindfulness',
                'Learning',
                'Fitness',
              ])
                Padding(
                  padding: const EdgeInsets.only(
                    right: AppSpacing.xxs + AppSpacing.xxxs,
                  ),
                  child: ChoiceChip(
                    label: AppText(cat),
                    selected: _habitCategory == cat,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelStyle: context.text.labelSmall,
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
                label: const AppText('Pin Note'),
                selected: _pinNote,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelStyle: context.text.labelSmall,
                onSelected: (v) => setState(() => _pinNote = v),
              ),
              AppSpacing.gapW8,
              for (final tag in [
                '@QuickCapture',
                '@Office',
                '@Market',
                '@Home',
                '@Vault',
              ])
                Padding(
                  padding: const EdgeInsets.only(
                    right: AppSpacing.xxs + AppSpacing.xxxs,
                  ),
                  child: ChoiceChip(
                    label: AppText(tag),
                    selected: _noteTag == tag,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelStyle: context.text.labelSmall,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxxs + 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadius.radiusSm,
      ),
      child: AppText.labelSmall(
        _intentLabel(_detectedIntent),
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }

  Widget _buildModeTab(
    IconData icon,
    String label,
    QuickCaptureMode mode,
    bool isDark,
  ) {
    final palette = context.palette;
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs + 1,
          vertical: AppSpacing.xxs + AppSpacing.xxxs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : palette.surfaceMuted,
          borderRadius: AppRadius.radiusMd,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppSpacing.md - 1,
              color: isSelected ? AppColors.textWhite : palette.icon,
            ),
            AppSpacing.gapW4,
            AppText.labelSmall(
              label,
              fontWeight: FontWeight.w700,
              color: isSelected ? AppColors.textWhite : palette.body,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, bool isDark, VoidCallback onTap) {
    final palette = context.palette;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs + AppSpacing.xxxs,
          vertical: AppSpacing.xxs + AppSpacing.xxxs,
        ),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: AppRadius.radiusFull,
          border: Border.all(color: palette.divider),
        ),
        child: AppText.captionBold(label, color: palette.body),
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
        return StringConstants.intentLabelExpense;
      case DetectedIntent.reminder:
        return StringConstants.intentLabelReminder;
      case DetectedIntent.habit:
        return StringConstants.intentLabelHabit;
      case DetectedIntent.note:
        return StringConstants.intentLabelNote;
    }
  }
}
