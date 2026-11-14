import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';

/// Single-surface editorial Daily Scratchpad card for instant zero-setup jotting.
///
/// Follows the Today Hub & Planner grouped-card language:
///   - Top header strip (`surfaceMuted` tint + `1px divider` hairline)
///   - Open borderless writing canvas (no nested box-inside-a-box)
///   - Quiet inline quick-insert actions (`• Bullet`, `☐ Todo`, `🕒 Time`)
class NotesScratchpadCard extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSaveAsNote;
  final VoidCallback onClear;

  const NotesScratchpadCard({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSaveAsNote,
    required this.onClear,
  });

  @override
  State<NotesScratchpadCard> createState() => _NotesScratchpadCardState();
}

class _NotesScratchpadCardState extends State<NotesScratchpadCard> {
  final FocusNode _focusNode = FocusNode();
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  void _insertToken(String token, {String? emptyFallback}) {
    HapticFeedback.selectionClick();
    final ctrl = widget.controller;
    final text = ctrl.text;
    final selection = ctrl.selection;

    final String nextText;
    final int cursorOffset;

    if (text.isEmpty) {
      final inserted = emptyFallback ?? token.trimLeft();
      nextText = inserted;
      cursorOffset = inserted.length;
    } else {
      final start = selection.isValid && selection.start >= 0
          ? selection.start
          : text.length;
      final end = selection.isValid && selection.end >= 0
          ? selection.end
          : text.length;
      final needsNewline = start > 0 && text[start - 1] != '\n';
      final insertion = needsNewline ? '\n$token' : token;
      nextText = text.replaceRange(start, end, insertion);
      cursorOffset = start + insertion.length;
    }

    ctrl.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
    widget.onChanged(nextText);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final isFocused = _focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: isFocused
              ? AppColors.moduleNotes.withValues(
                  alpha: palette.isDark ? 0.55 : 0.45,
                )
              : palette.divider,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Header Strip ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: palette.surfaceMuted.withValues(
                alpha: palette.isDark ? 0.42 : 0.62,
              ),
              border: _isCollapsed
                  ? null
                  : Border(bottom: BorderSide(color: palette.divider)),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.moduleNotes.withValues(
                      alpha: palette.isDark ? 0.22 : 0.14,
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: AppColors.moduleNotes,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      StringConstants.dailyScratchpad.toUpperCase(),
                      maxLines: 1,
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        letterSpacing: 0.55,
                        color: AppColors.moduleNotes,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: widget.controller,
                    builder: (context, value, _) {
                      final hasText = value.text.trim().isNotEmpty;
                      if (!hasText) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.card,
                                  borderRadius: AppRadius.radiusFull,
                                  border: Border.all(color: palette.divider),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: AppColors.moduleNotes,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Instant auto-save',
                                        maxLines: 1,
                                        style: textTheme.labelSmall?.copyWith(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: palette.caption,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              borderRadius: BorderRadius.circular(7),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _isCollapsed = !_isCollapsed);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Icon(
                                  _isCollapsed
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.keyboard_arrow_up_rounded,
                                  size: 17,
                                  color: palette.caption,
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: widget.onSaveAsNote,
                              child: Container(
                                height: 27,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.moduleNotes,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.bookmark_add_outlined,
                                      size: 13.5,
                                      color: AppColors.textWhite,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      StringConstants.save,
                                      style: textTheme.labelMedium?.copyWith(
                                        fontSize: 11.5,
                                        color: AppColors.textWhite,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Tooltip(
                              message: 'Clear scratchpad',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: widget.onClear,
                                child: Container(
                                  width: 27,
                                  height: 27,
                                  decoration: BoxDecoration(
                                    color: palette.card,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: palette.divider),
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: palette.caption,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── 2. Open Writing Pad + Quick Tokens ──────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _isCollapsed
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 11, 14, 8),
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          onChanged: widget.onChanged,
                          minLines: 2,
                          maxLines: 5,
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: 13.5,
                            height: 1.45,
                            color: palette.heading,
                          ),
                          decoration: InputDecoration(
                            filled: false,
                            isDense: true,
                            hintText: StringConstants.scratchpadHint,
                            hintStyle: textTheme.bodyMedium?.copyWith(
                              fontSize: 13.5,
                              height: 1.45,
                              color: palette.caption,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: AppSpacing.edgeInsetsZero,
                          ),
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: palette.divider),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: widget.controller,
                          builder: (context, value, _) {
                            final trimmed = value.text.trim();
                            final words = trimmed.isEmpty
                                ? 0
                                : trimmed.split(RegExp(r'\s+')).length;
                            return Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _ScratchpadQuickAction(
                                          icon: Icons.check_box_outlined,
                                          label: 'Todo',
                                          onTap: () => _insertToken(
                                            '[ ] ',
                                            emptyFallback: '[ ] ',
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        _ScratchpadQuickAction(
                                          icon: Icons
                                              .format_list_bulleted_rounded,
                                          label: 'Bullet',
                                          onTap: () => _insertToken(
                                            '• ',
                                            emptyFallback: '• ',
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        _ScratchpadQuickAction(
                                          icon: Icons.schedule_rounded,
                                          label: 'Time',
                                          onTap: () {
                                            final stamp = DateFormat(
                                              'h:mm a',
                                            ).format(DateTime.now());
                                            _insertToken(
                                              '[$stamp] ',
                                              emptyFallback: '[$stamp] ',
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (words > 0) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '$words ${words == 1 ? 'word' : 'words'}',
                                    style: textTheme.labelSmall?.copyWith(
                                      fontSize: 10.5,
                                      color: palette.caption,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ScratchpadQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ScratchpadQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.moduleNotes),
            const SizedBox(width: 4),
            Text(
              label,
              style: context.text.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: palette.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
