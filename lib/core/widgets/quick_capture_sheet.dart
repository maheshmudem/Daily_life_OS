import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../constants/string_constants.dart';

enum QuickCaptureMode { text, voice, scan }

enum DetectedIntent { expense, reminder, note, vault }

class QuickCaptureSheet extends StatefulWidget {
  final QuickCaptureMode initialMode;

  const QuickCaptureSheet({
    super.key,
    this.initialMode = QuickCaptureMode.text,
  });

  static Future<void> show(BuildContext context, {QuickCaptureMode mode = QuickCaptureMode.text}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickCaptureSheet(initialMode: mode),
    );
  }

  @override
  State<QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends State<QuickCaptureSheet>
    with SingleTickerProviderStateMixin {
  late QuickCaptureMode _mode;
  final TextEditingController _textController = TextEditingController();
  bool _isRecording = false;
  DetectedIntent _detectedIntent = DetectedIntent.reminder;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    if (_mode == QuickCaptureMode.voice) {
      _isRecording = true;
    }

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _textController.addListener(_parseIntent);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _parseIntent() {
    final text = _textController.text.toLowerCase();
    if (text.contains('spent') ||
        text.contains('paid') ||
        text.contains('bought') ||
        text.contains('rs') ||
        text.contains('₹') ||
        text.contains('bill') ||
        text.contains('cost')) {
      setState(() => _detectedIntent = DetectedIntent.expense);
    } else if (text.contains('password') ||
        text.contains('pin') ||
        text.contains('secret') ||
        text.contains('warranty')) {
      setState(() => _detectedIntent = DetectedIntent.vault);
    } else if (text.contains('remind') ||
        text.contains('at') ||
        text.contains('tomorrow') ||
        text.contains('pm') ||
        text.contains('am') ||
        text.contains('call') ||
        text.contains('meeting')) {
      setState(() => _detectedIntent = DetectedIntent.reminder);
    } else {
      setState(() => _detectedIntent = DetectedIntent.note);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
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
                color: isDark ? AppColors.darkDivider : AppColors.divider,
                borderRadius: AppRadius.radiusFull,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header with mode selector pills
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    StringConstants.quickCaptureTitle,
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(width: 8),
                  _buildIntentBadge(),
                ],
              ),
              Row(
                children: [
                  _buildModeTab(Icons.keyboard_rounded, QuickCaptureMode.text),
                  const SizedBox(width: 6),
                  _buildModeTab(Icons.mic_rounded, QuickCaptureMode.voice),
                  const SizedBox(width: 6),
                  _buildModeTab(Icons.document_scanner_rounded, QuickCaptureMode.scan),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dynamic Body based on Mode
          if (_mode == QuickCaptureMode.voice)
            _buildVoiceRecordingView(isDark)
          else if (_mode == QuickCaptureMode.scan)
            _buildScanView(isDark)
          else
            _buildTextInputView(isDark),

          const SizedBox(height: 16),

          // Quick Suggestion Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChip('Spent ₹450 Electricity', () {
                  _textController.text = 'Spent ₹450 on electricity bill';
                }),
                AppSpacing.gapW8,
                _buildQuickChip('Call Bank Tomorrow 5PM', () {
                  _textController.text = 'Call bank tomorrow at 5pm';
                }),
                AppSpacing.gapW8,
                _buildQuickChip('Buy charger @Market', () {
                  _textController.text = 'Buy phone charger @Market';
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Save / Execute Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Action logged to ${_intentLabel(_detectedIntent)}!',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _intentColor(_detectedIntent),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
                elevation: 0,
              ),
              icon: const Icon(Icons.bolt_rounded),
              label: Text(
                'Log to ${_intentLabel(_detectedIntent)} (Instant)',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputView(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: TextField(
        controller: _textController,
        autofocus: true,
        maxLines: 3,
        style: TextStyle(
          color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: StringConstants.quickCaptureHint,
          hintStyle: TextStyle(
            color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.all(14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildVoiceRecordingView(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.voiceWaveform.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: AppColors.voiceWaveform.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(12, (index) {
              return AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  final height = 12.0 +
                      (24.0 *
                          ((_waveController.value + (index * 0.15)) % 1.0));
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 4,
                    height: height,
                    decoration: BoxDecoration(
                      color: AppColors.voiceWaveform,
                      borderRadius: AppRadius.radiusFull,
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 14),
          Text(
            _isRecording ? 'Listening... Speak your thought naturally' : 'Voice capture paused',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.voiceWaveform,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '"Spent 450 on electricity bill" -> Auto creates expense & marks reminder done',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanView(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.moduleMoney.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: AppColors.moduleMoney.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.document_scanner_rounded, size: 40, color: AppColors.moduleMoney),
          const SizedBox(height: 10),
          const Text(
            'Camera OCR Text & Bill Grabber',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.moduleMoney,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Scan physical bills, store warranty receipts, or convert book notes',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
            ),
          ),
        ],
      ),
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

  Widget _buildModeTab(IconData icon, QuickCaptureMode mode) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mode = mode;
          _isRecording = mode == QuickCaptureMode.voice;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: AppRadius.radiusMd,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : AppColors.iconColor,
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: AppRadius.radiusFull,
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textBody,
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
      case DetectedIntent.vault:
        return AppColors.moduleVault;
      case DetectedIntent.note:
        return AppColors.moduleNotes;
    }
  }

  String _intentLabel(DetectedIntent intent) {
    switch (intent) {
      case DetectedIntent.expense:
        return 'Money / Expense';
      case DetectedIntent.reminder:
        return 'Planner / Reminder';
      case DetectedIntent.vault:
        return 'Secure Vault';
      case DetectedIntent.note:
        return 'Notes / Idea';
    }
  }
}
