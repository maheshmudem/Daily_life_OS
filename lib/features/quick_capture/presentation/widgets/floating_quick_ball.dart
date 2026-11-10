import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';
import '../../domain/entities/quick_capture_entities.dart';

/// A movable, minimizable Floating Quick-Capture Ball & Morphing Capsule
/// inspired by iOS AssistiveTouch, Dynamic Island, and Xiaomi Quick Ball.
class FloatingQuickBall extends StatefulWidget {
  final ValueChanged<QuickCaptureMode> onSelectMode;
  final VoidCallback? onOpenSpotlight;
  final bool initiallyExpanded;

  const FloatingQuickBall({
    super.key,
    required this.onSelectMode,
    this.onOpenSpotlight,
    this.initiallyExpanded = false,
  });

  @override
  State<FloatingQuickBall> createState() => _FloatingQuickBallState();
}

class _FloatingQuickBallState extends State<FloatingQuickBall>
    with SingleTickerProviderStateMixin {
  static const String _prefKeyXRatio = 'quick_ball_x_ratio_v1';
  static const String _prefKeyYRatio = 'quick_ball_y_ratio_v1';

  static const double _ballSize = AppSpacing.huge + AppSpacing.xxs + 2.0;
  static const double _edgeMargin = AppSpacing.sm;

  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;

  final ValueNotifier<Offset> _ratioNotifier = ValueNotifier<Offset>(
    const Offset(1.0, 0.96),
  );

  bool _isExpanded = false;
  bool _isDragging = false;
  Size _lastViewportSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: _isExpanded ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _loadSavedPosition();
  }

  Future<void> _loadSavedPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedX = prefs.getDouble(_prefKeyXRatio);
      final savedY = prefs.getDouble(_prefKeyYRatio);
      if (savedX != null && savedY != null && mounted) {
        _ratioNotifier.value = Offset(
          savedX.clamp(0.0, 1.0),
          savedY.clamp(0.0, 1.0),
        );
      }
    } catch (_) {}
  }

  Future<void> _savePosition(Offset ratio) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefKeyXRatio, ratio.dx.clamp(0.0, 1.0));
      await prefs.setDouble(_prefKeyYRatio, ratio.dy.clamp(0.0, 1.0));
    } catch (_) {}
  }

  @override
  void dispose() {
    _expandController.dispose();
    _ratioNotifier.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    HapticFeedback.selectionClick();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  void _triggerModeAndCollapse(QuickCaptureMode mode) {
    HapticFeedback.mediumImpact();
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _expandController.reverse();
      });
    }
    widget.onSelectMode(mode);
  }

  void _onPanStart(DragStartDetails details) {
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails details, Size viewport) {
    if (viewport.width <= 0 || viewport.height <= 0) return;
    const minX = _edgeMargin;
    final maxX = math.max(minX, viewport.width - _ballSize - _edgeMargin);
    const minY = _edgeMargin + AppSpacing.xs;
    final maxY = math.max(minY, viewport.height - _ballSize - _edgeMargin);

    final usableW = math.max(1.0, maxX - minX);
    final usableH = math.max(1.0, maxY - minY);

    final currentRatio = _ratioNotifier.value;
    final currentX = minX + currentRatio.dx * usableW;
    final currentY = minY + currentRatio.dy * usableH;

    final nextX = (currentX + details.delta.dx).clamp(minX, maxX);
    final nextY = (currentY + details.delta.dy).clamp(minY, maxY);

    _ratioNotifier.value = Offset(
      ((nextX - minX) / usableW).clamp(0.0, 1.0),
      ((nextY - minY) / usableH).clamp(0.0, 1.0),
    );
  }

  void _onPanEnd(DragEndDetails details) {
    if (mounted) {
      setState(() => _isDragging = false);
    }
    if (_lastViewportSize.width > 0 && _lastViewportSize.height > 0) {
      final vx = details.velocity.pixelsPerSecond.dx;
      final vy = details.velocity.pixelsPerSecond.dy;
      if (vx.abs() > 80 || vy.abs() > 80) {
        const minX = _edgeMargin;
        final maxX = math.max(
          minX,
          _lastViewportSize.width - _ballSize - _edgeMargin,
        );
        const minY = _edgeMargin + AppSpacing.xs;
        final maxY = math.max(
          minY,
          _lastViewportSize.height - _ballSize - _edgeMargin,
        );
        final usableW = math.max(1.0, maxX - minX);
        final usableH = math.max(1.0, maxY - minY);

        final currentRatio = _ratioNotifier.value;
        final projectedX = (minX + currentRatio.dx * usableW + vx * 0.06).clamp(
          minX,
          maxX,
        );
        final projectedY = (minY + currentRatio.dy * usableH + vy * 0.06).clamp(
          minY,
          maxY,
        );
        _ratioNotifier.value = Offset(
          ((projectedX - minX) / usableW).clamp(0.0, 1.0),
          ((projectedY - minY) / usableH).clamp(0.0, 1.0),
        );
      }
    }
    _savePosition(_ratioNotifier.value);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        _lastViewportSize = viewport;

        const minX = _edgeMargin;
        final maxX = math.max(minX, viewport.width - _ballSize - _edgeMargin);
        const minY = _edgeMargin + AppSpacing.xs;
        final maxY = math.max(minY, viewport.height - _ballSize - _edgeMargin);

        final usableW = math.max(1.0, maxX - minX);
        final usableH = math.max(1.0, maxY - minY);

        final expandedWidth = math.min(
          viewport.width - (_edgeMargin * 2),
          364.0,
        );

        return ValueListenableBuilder<Offset>(
          valueListenable: _ratioNotifier,
          builder: (context, ratio, _) {
            final ballX = minX + (ratio.dx.clamp(0.0, 1.0) * usableW);
            final ballY = minY + (ratio.dy.clamp(0.0, 1.0) * usableH);

            final isRightHalf = ratio.dx >= 0.5;
            final rawExpandedLeft = isRightHalf
                ? (ballX + _ballSize - expandedWidth)
                : ballX;
            final clampedExpandedLeft = rawExpandedLeft.clamp(
              _edgeMargin,
              math.max(
                _edgeMargin,
                viewport.width - expandedWidth - _edgeMargin,
              ),
            );

            return AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, _) {
                final t = _expandAnimation.value;
                final currentWidth = ui.lerpDouble(
                  _ballSize,
                  expandedWidth,
                  t,
                )!;
                final currentLeft = ui.lerpDouble(
                  ballX,
                  clampedExpandedLeft,
                  t,
                )!;

                final collapsedOpacity = (1.0 - (t * 2.2)).clamp(0.0, 1.0);
                final expandedOpacity = ((t - 0.2) / 0.8).clamp(0.0, 1.0);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: currentLeft,
                      top: ballY,
                      width: currentWidth,
                      height: _ballSize,
                      child: RepaintBoundary(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: _onPanStart,
                          onPanUpdate: (d) => _onPanUpdate(d, viewport),
                          onPanEnd: _onPanEnd,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: (_isExpanded || _isDragging) ? 1.0 : 0.92,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.darkScaffoldBackground,
                                    AppColors.primaryDark,
                                    AppColors.darkScaffoldBackground,
                                  ],
                                ),
                                borderRadius: AppRadius.radiusFull,
                                border: Border.all(
                                  color: _isDragging
                                      ? AppColors.voiceWaveform.withValues(
                                          alpha: 0.75,
                                        )
                                      : AppColors.primaryLight.withValues(
                                          alpha: 0.38,
                                        ),
                                  width: _isDragging ? 1.5 : 1.1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.darkScaffoldBackground
                                        .withValues(
                                          alpha: _isDragging ? 0.55 : 0.38,
                                        ),
                                    blurRadius: _isDragging
                                        ? AppSpacing.xl
                                        : AppSpacing.md,
                                    offset: const Offset(0, AppSpacing.xxs),
                                  ),
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: _isExpanded ? 0.22 : 0.16,
                                    ),
                                    blurRadius: AppSpacing.sm,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: AppRadius.radiusFull,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (collapsedOpacity > 0)
                                      IgnorePointer(
                                        ignoring: _isExpanded,
                                        child: Opacity(
                                          opacity: collapsedOpacity,
                                          child: _buildCollapsedBallContent(),
                                        ),
                                      ),
                                    if (expandedOpacity > 0)
                                      IgnorePointer(
                                        ignoring: !_isExpanded,
                                        child: Opacity(
                                          opacity: expandedOpacity,
                                          child: OverflowBox(
                                            minWidth: expandedWidth,
                                            maxWidth: expandedWidth,
                                            minHeight: _ballSize,
                                            maxHeight: _ballSize,
                                            alignment: Alignment.center,
                                            child: SizedBox(
                                              width: expandedWidth,
                                              height: _ballSize,
                                              child:
                                                  _buildExpandedCapsuleContent(),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCollapsedBallContent() {
    return Tooltip(
      message: StringConstants.quickCaptureTitle,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const ValueKey('quick_capture_ball'),
          borderRadius: AppRadius.radiusFull,
          onTap: _toggleExpanded,
          onLongPress: () => _triggerModeAndCollapse(QuickCaptureMode.voice),
          child: SizedBox(
            width: _ballSize,
            height: _ballSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: AppSpacing.xxl + AppSpacing.xs,
                  height: AppSpacing.xxl + AppSpacing.xs,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.32),
                        AppColors.voiceWaveform.withValues(alpha: 0.26),
                      ],
                    ),
                  ),
                ),
                const Icon(
                  Icons.bolt_rounded,
                  color: AppColors.textWhite,
                  size: AppSpacing.lg + AppSpacing.xxxs,
                ),
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.sm - AppSpacing.xxxs,
                  child: Container(
                    width: AppSpacing.xxs + 1,
                    height: AppSpacing.xxs + 1,
                    decoration: const BoxDecoration(
                      color: AppColors.voiceWaveform,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: AppSpacing.xs,
                  left: AppSpacing.sm - AppSpacing.xxxs,
                  child: Container(
                    width: AppSpacing.xxs,
                    height: AppSpacing.xxs,
                    decoration: const BoxDecoration(
                      color: AppColors.moduleMoneyLight,
                      shape: BoxShape.circle,
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

  Widget _buildExpandedCapsuleContent() {
    final pillTextStyle = AppTextStyles.label.copyWith(
      color: AppColors.textWhite,
      fontWeight: FontWeight.w700,
    );

    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xxxs,
                right: AppSpacing.xxs,
              ),
              child: Icon(
                Icons.drag_indicator_rounded,
                size: AppSpacing.md - 1,
                color: AppColors.textWhite.withValues(alpha: 0.38),
              ),
            ),

            // 1. Hold to Speak (Voice)
            Expanded(
              flex: 5,
              child: InkWell(
                borderRadius: AppRadius.radiusFull,
                onTap: () => _triggerModeAndCollapse(QuickCaptureMode.voice),
                onLongPress: () =>
                    _triggerModeAndCollapse(QuickCaptureMode.voice),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxs,
                    vertical: AppSpacing.xxs + AppSpacing.xxxs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xxs + 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.voiceWaveform.withValues(
                            alpha: 0.22,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: AppColors.voiceWaveform,
                          size: AppSpacing.md - 1,
                        ),
                      ),
                      AppSpacing.gapW4,
                      Flexible(
                        child: Text(
                          StringConstants.holdToSpeak,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: pillTextStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Container(
              width: 1,
              height: AppSpacing.md + AppSpacing.xxxs,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxs),
              color: AppColors.textWhite.withValues(alpha: 0.15),
            ),

            // 2. Quick Type
            Expanded(
              flex: 4,
              child: InkWell(
                borderRadius: AppRadius.radiusFull,
                onTap: () => _triggerModeAndCollapse(QuickCaptureMode.text),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxs,
                    vertical: AppSpacing.xxs + AppSpacing.xxxs,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_rounded,
                        color: AppColors.textWhite.withValues(alpha: 0.75),
                        size: AppSpacing.md,
                      ),
                      AppSpacing.gapW4,
                      Flexible(
                        child: Text(
                          StringConstants.quickType,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: pillTextStyle.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Container(
              width: 1,
              height: AppSpacing.md + AppSpacing.xxxs,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxs),
              color: AppColors.textWhite.withValues(alpha: 0.15),
            ),

            // 3. Scan Bill / OCR
            Tooltip(
              message: StringConstants.scanText,
              child: InkWell(
                borderRadius: AppRadius.radiusFull,
                onTap: () => _triggerModeAndCollapse(QuickCaptureMode.scan),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs + AppSpacing.xxxs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.document_scanner_rounded,
                        color: AppColors.moduleMoneyLight,
                        size: AppSpacing.md,
                      ),
                      AppSpacing.gapW4,
                      Text(
                        'Scan',
                        style: pillTextStyle.copyWith(
                          color: AppColors.textWhite.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (widget.onOpenSpotlight != null) ...[
              const SizedBox(width: AppSpacing.xxxs),
              Tooltip(
                message: StringConstants.spotlightSearchTooltip,
                child: InkWell(
                  key: const ValueKey('quick_ball_spotlight'),
                  borderRadius: AppRadius.radiusFull,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    if (_isExpanded) {
                      setState(() {
                        _isExpanded = false;
                        _expandController.reverse();
                      });
                    }
                    widget.onOpenSpotlight!();
                  },
                  child: Container(
                    width: AppSpacing.xl + AppSpacing.xxs,
                    height: AppSpacing.xl + AppSpacing.xxs,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      size: AppSpacing.md - 1,
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
              ),
            ],

            AppSpacing.gapW4,

            // 4. Minimize back to Quick Ball button
            Tooltip(
              message: 'Minimize to Quick Ball',
              child: InkWell(
                key: const ValueKey('minimize_quick_ball'),
                borderRadius: AppRadius.radiusFull,
                onTap: _toggleExpanded,
                child: Container(
                  width: AppSpacing.xl + AppSpacing.xxs,
                  height: AppSpacing.xl + AppSpacing.xxs,
                  decoration: BoxDecoration(
                    color: AppColors.textWhite.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_fullscreen_rounded,
                    size: AppSpacing.sm + AppSpacing.xxxs,
                    color: AppColors.textWhite.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
