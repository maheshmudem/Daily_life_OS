import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/widgets/app_dropdown_menu.dart';
import '../../../../core/widgets/expandable_text_widget.dart';
import '../../domain/entities/note_entity.dart';

/// Editorial note card used in both List and Masonry Grid views on [NotesPage].
///
/// Designed to match the calm, hairline-bordered visual language of Today Hub
/// and Planner:
///   - `palette.card` surface with `1px palette.divider` border (subtle accent
///     tint when pinned)
///   - Contextual squircle icon badge + crisp 2-line title + overflow menu
///   - Inline interactive checklist with live progress bar
///   - Tappable `@tag` pills + quiet footer metadata & quick actions
class NoteCardWidget extends StatelessWidget {
  final NoteEntity note;
  final bool isCompactGrid;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final VoidCallback onDuplicate;
  final VoidCallback onCopy;
  final VoidCallback onConvertToTask;
  final VoidCallback onPushToTimeline;
  final VoidCallback onConvertToExpense;
  final VoidCallback onDelete;
  final ValueChanged<int> onToggleChecklistLine;
  final ValueChanged<String>? onSelectTag;

  const NoteCardWidget({
    super.key,
    required this.note,
    this.isCompactGrid = false,
    required this.onTap,
    required this.onTogglePin,
    required this.onDuplicate,
    required this.onCopy,
    required this.onConvertToTask,
    required this.onPushToTimeline,
    required this.onConvertToExpense,
    required this.onDelete,
    required this.onToggleChecklistLine,
    this.onSelectTag,
  });

  IconData _resolveContextualIcon() {
    if (note.hasChecklist) return Icons.checklist_rounded;
    if (note.isPinned) return Icons.push_pin_rounded;

    final lowerTags = note.tags.map((t) => t.toLowerCase()).toList();
    if (lowerTags.any((t) => t.contains('idea'))) {
      return Icons.lightbulb_outline_rounded;
    }
    if (lowerTags.any((t) => t.contains('work') || t.contains('office'))) {
      return Icons.work_outline_rounded;
    }
    if (lowerTags.any((t) => t.contains('shop') || t.contains('market'))) {
      return Icons.shopping_bag_outlined;
    }
    if (lowerTags.any((t) => t.contains('finance') || t.contains('bill'))) {
      return Icons.account_balance_wallet_outlined;
    }
    if (lowerTags.any((t) => t.contains('scratchpad'))) {
      return Icons.bolt_rounded;
    }
    if (lowerTags.any((t) => t.contains('personal') || t.contains('home'))) {
      return Icons.favorite_border_rounded;
    }
    return Icons.sticky_note_2_outlined;
  }

  static String _formatRelativeDate(String isoString) {
    final parsed = DateTime.tryParse(isoString);
    if (parsed == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);
    final diff = today.difference(dateOnly).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (parsed.year == now.year) return DateFormat('d MMM').format(parsed);
    return DateFormat('d MMM yy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final noteColor = note.color;

    final lines = note.content.split('\n');
    final checklistIndices = <int>[];
    final proseLines = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (NoteEntity.isChecklistLine(line)) {
        checklistIndices.add(i);
      } else if (line.trim().isNotEmpty) {
        proseLines.add(line);
      }
    }

    final proseContent = proseLines.join('\n').trim();
    final nonEmptyTags = note.tags.where((t) => t.trim().isNotEmpty).toList();
    final maxTags = isCompactGrid ? 2 : 5;
    final visibleTags = nonEmptyTags.take(maxTags).toList();
    final hiddenTagCount = nonEmptyTags.length - visibleTags.length;

    final horizontalPad = isCompactGrid ? 12.0 : 15.0;
    final verticalPad = isCompactGrid ? 12.0 : 14.0;

    final borderColor = note.isPinned
        ? noteColor.withValues(alpha: palette.isDark ? 0.50 : 0.42)
        : palette.divider;

    final dateText = _formatRelativeDate(note.updatedAt);
    final metaDetail = checklistIndices.isNotEmpty
        ? '${note.checklistDoneCount}/${note.checklistTotalCount} done'
        : '${note.wordCount} ${note.wordCount == 1 ? 'word' : 'words'}';
    final footerMeta = dateText.isNotEmpty
        ? '$dateText · $metaDetail'
        : metaDetail;

    return Material(
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLg,
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPad,
            vertical: verticalPad,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 1. Header: Contextual Badge + Title + Pin + Menu ───────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isCompactGrid ? 26 : 28,
                    height: isCompactGrid ? 26 : 28,
                    decoration: BoxDecoration(
                      color: noteColor.withValues(
                        alpha: palette.isDark ? 0.20 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      _resolveContextualIcon(),
                      size: isCompactGrid ? 14 : 15,
                      color: noteColor,
                    ),
                  ),
                  SizedBox(width: isCompactGrid ? 8 : 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        note.title.trim().isNotEmpty
                            ? note.title.trim()
                            : 'Untitled Note',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontSize: isCompactGrid ? 14 : 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.25,
                          height: 1.25,
                          color: note.title.trim().isNotEmpty
                              ? palette.heading
                              : palette.secondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (!isCompactGrid || note.isPinned)
                    Tooltip(
                      message: note.isPinned ? 'Unpin note' : 'Pin note',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(7),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onTogglePin();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            note.isPinned
                                ? Icons.push_pin_rounded
                                : Icons.push_pin_outlined,
                            size: 15,
                            color: note.isPinned
                                ? noteColor
                                : palette.caption.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ),
                  _buildOverflowMenu(context),
                ],
              ),

              // ── 2. Prose Preview ───────────────────────────────────────────
              if (proseContent.isNotEmpty) ...[
                const SizedBox(height: 9),
                ExpandableTextWidget(
                  text: proseContent,
                  collapsedMaxLines: isCompactGrid ? 4 : 3,
                  toggleColor: noteColor,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: isCompactGrid ? 12.5 : 13.5,
                    height: 1.45,
                    color: palette.body,
                  ),
                ),
              ],

              // ── 3. Interactive Checklist Block ─────────────────────────────
              if (checklistIndices.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildChecklistContainer(
                  context,
                  lines: lines,
                  checklistIndices: checklistIndices,
                  noteColor: noteColor,
                ),
              ],

              // ── 4. Tappable @Tag Pills ─────────────────────────────────────
              if (visibleTags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    for (final tag in visibleTags)
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: onSelectTag != null
                            ? () {
                                HapticFeedback.selectionClick();
                                onSelectTag!(tag);
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: noteColor.withValues(
                              alpha: palette.isDark ? 0.16 : 0.10,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: noteColor,
                            ),
                          ),
                        ),
                      ),
                    if (hiddenTagCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surfaceMuted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+$hiddenTagCount',
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: palette.caption,
                          ),
                        ),
                      ),
                  ],
                ),
              ],

              // ── 5. Quiet Editorial Footer ──────────────────────────────────
              const SizedBox(height: 11),
              Divider(height: 1, thickness: 1, color: palette.divider),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      footerMeta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        color: palette.caption,
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _FooterGhostAction(
                    icon: Icons.add_task_rounded,
                    label: isCompactGrid ? 'Task' : '+ Task',
                    color: AppColors.moduleTime,
                    onTap: onConvertToTask,
                  ),
                  if (!isCompactGrid) ...[
                    const SizedBox(width: 4),
                    _FooterGhostAction(
                      icon: Icons.payments_outlined,
                      label: 'Expense',
                      color: AppColors.moduleMoney,
                      onTap: onConvertToExpense,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistContainer(
    BuildContext context, {
    required List<String> lines,
    required List<int> checklistIndices,
    required Color noteColor,
  }) {
    final palette = context.palette;
    final textTheme = context.text;
    final maxVisible = isCompactGrid ? 4 : 6;
    final shownIndices = checklistIndices.take(maxVisible).toList();
    final remaining = checklistIndices.length - shownIndices.length;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompactGrid ? 9 : 11,
        vertical: isCompactGrid ? 8 : 9,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceMuted.withValues(
          alpha: palette.isDark ? 0.42 : 0.60,
        ),
        borderRadius: AppRadius.radiusSm,
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.radiusFull,
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    value: note.checklistProgress,
                    backgroundColor: palette.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(noteColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${note.checklistDoneCount}/${note.checklistTotalCount}',
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: palette.caption,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final idx in shownIndices)
            _buildChecklistItemRow(
              context,
              line: lines[idx],
              lineIndex: idx,
              noteColor: noteColor,
            ),
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+$remaining more ${remaining == 1 ? 'item' : 'items'}',
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: palette.caption,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChecklistItemRow(
    BuildContext context, {
    required String line,
    required int lineIndex,
    required Color noteColor,
  }) {
    final palette = context.palette;
    final textTheme = context.text;
    final checked = NoteEntity.isCheckedLine(line);
    final label = line.trimLeft().substring(4);

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => onToggleChecklistLine(lineIndex),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                checked
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 15.5,
                color: checked ? noteColor : palette.caption,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                maxLines: isCompactGrid ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: isCompactGrid ? 12 : 12.8,
                  height: 1.35,
                  color: checked ? palette.caption : palette.heading,
                  decoration: checked ? TextDecoration.lineThrough : null,
                  decorationColor: palette.caption,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverflowMenu(BuildContext context) {
    final palette = context.palette;

    return AppDropdownMenu<String>(
      tooltip: 'Note actions',
      menuConstraints: const BoxConstraints(minWidth: 168, maxWidth: 215),
      icon: Icon(Icons.more_horiz_rounded, size: 18, color: palette.caption),
      onSelected: (action) {
        switch (action) {
          case 'edit':
            onTap();
            break;
          case 'pin':
            onTogglePin();
            break;
          case 'duplicate':
            onDuplicate();
            break;
          case 'copy':
            onCopy();
            break;
          case 'convert_task':
            onConvertToTask();
            break;
          case 'push_timeline':
            onPushToTimeline();
            break;
          case 'convert_expense':
            onConvertToExpense();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      items: [
        AppDropdownItem<String>(
          value: 'edit',
          icon: Icons.edit_outlined,
          label: StringConstants.edit,
          tintColor: palette.heading,
        ),
        AppDropdownItem<String>(
          value: 'pin',
          icon: note.isPinned
              ? Icons.push_pin_outlined
              : Icons.push_pin_rounded,
          label: note.isPinned ? 'Unpin' : 'Pin to Top',
          tintColor: note.isPinned ? AppColors.moduleNotes : palette.heading,
        ),
        AppDropdownItem<String>(
          value: 'duplicate',
          icon: Icons.control_point_duplicate_rounded,
          label: 'Duplicate',
          tintColor: palette.heading,
        ),
        AppDropdownItem<String>(
          value: 'copy',
          icon: Icons.copy_rounded,
          label: 'Copy Text',
          tintColor: palette.heading,
        ),
        AppDropdownItem<String>(
          value: 'convert_task',
          icon: Icons.add_task_rounded,
          label: 'Add to Planner',
          tintColor: AppColors.moduleTime,
        ),
        AppDropdownItem<String>(
          value: 'push_timeline',
          icon: Icons.today_rounded,
          label: StringConstants.pushToTodayTimeline,
          tintColor: AppColors.primary,
        ),
        AppDropdownItem<String>(
          value: 'convert_expense',
          icon: Icons.payments_outlined,
          label: StringConstants.convertToExpense,
          tintColor: AppColors.moduleMoney,
        ),
        const AppDropdownDivider(),
        AppDropdownItem<String>(
          value: 'delete',
          icon: Icons.delete_outline_rounded,
          label: StringConstants.delete,
          isDestructive: true,
        ),
      ],
    );
  }
}

class _FooterGhostAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FooterGhostAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextButton(
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        backgroundColor: palette.surfaceMuted.withValues(
          alpha: palette.isDark ? 0.55 : 0.85,
        ),
        foregroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: context.text.labelSmall?.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: palette.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
