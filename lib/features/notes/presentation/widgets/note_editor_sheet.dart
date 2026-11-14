import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../domain/entities/note_entity.dart';
import '../bloc/notes_bloc.dart';

/// Refined editorial modal composer for creating and editing notes.
class NoteEditorSheet extends StatefulWidget {
  final NoteEntity? note;
  final List<int> colorPalette;
  final List<String> suggestedTags;

  const NoteEditorSheet({
    super.key,
    this.note,
    required this.colorPalette,
    required this.suggestedTags,
  });

  static Future<void> show(
    BuildContext context, {
    NoteEntity? note,
    required List<int> colorPalette,
    required List<String> suggestedTags,
  }) {
    final notesBloc = context.read<NotesBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: notesBloc,
        child: NoteEditorSheet(
          note: note,
          colorPalette: colorPalette,
          suggestedTags: suggestedTags,
        ),
      ),
    );
  }

  @override
  State<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<NoteEditorSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _customTagCtrl;
  final FocusNode _contentFocusNode = FocusNode();

  late int _selectedColor;
  late bool _isPinned;
  late List<String> _activeTags;
  String? _validationError;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.note?.content ?? '');
    _customTagCtrl = TextEditingController();
    _selectedColor = widget.note?.colorValue ?? widget.colorPalette.first;
    _isPinned = widget.note?.isPinned ?? false;
    _activeTags = widget.note != null
        ? List<String>.from(widget.note!.tags.where((t) => t.trim().isNotEmpty))
        : <String>[];
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _customTagCtrl.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _insertFormatting(String token, {bool ensureNewLine = true}) {
    HapticFeedback.selectionClick();
    final text = _contentCtrl.text;
    final selection = _contentCtrl.selection;

    final String nextText;
    final int cursorOffset;

    if (text.isEmpty) {
      nextText = token;
      cursorOffset = token.length;
    } else {
      final start = selection.isValid && selection.start >= 0
          ? selection.start
          : text.length;
      final end = selection.isValid && selection.end >= 0
          ? selection.end
          : text.length;
      final needsLeadingBreak =
          ensureNewLine && start > 0 && text[start - 1] != '\n';
      final insertion = needsLeadingBreak ? '\n$token' : token;
      nextText = text.replaceRange(start, end, insertion);
      cursorOffset = start + insertion.length;
    }

    setState(() {
      _validationError = null;
      _contentCtrl.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: cursorOffset),
      );
    });
    _contentFocusNode.requestFocus();
  }

  void _addCustomTag() {
    var raw = _customTagCtrl.text.trim();
    if (raw.isEmpty) return;
    if (!raw.startsWith('@')) {
      raw = '@$raw';
    }
    HapticFeedback.selectionClick();
    setState(() {
      if (!_activeTags.contains(raw)) {
        _activeTags.add(raw);
      }
      _customTagCtrl.clear();
    });
  }

  Future<void> _confirmDelete() async {
    final existing = widget.note;
    if (existing == null) return;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Note?',
      message:
          'Are you sure you want to delete "${existing.title}"? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      context.read<NotesBloc>().add(DeleteNote(existing.id));
      Navigator.of(context).pop();
    }
  }

  void _submit() {
    final rawTitle = _titleCtrl.text.trim();
    final rawContent = _contentCtrl.text.trim();

    if (rawTitle.isEmpty && rawContent.isEmpty) {
      setState(() {
        _validationError = 'Enter a note title or write some content first.';
      });
      return;
    }

    final resolvedTitle = rawTitle.isNotEmpty
        ? rawTitle
        : (rawContent.split('\n').first.length > 42
              ? '${rawContent.split('\n').first.substring(0, 42)}...'
              : rawContent.split('\n').first);

    final joinedTags = _activeTags.join(',');
    final bloc = context.read<NotesBloc>();

    HapticFeedback.lightImpact();
    if (_isEditing) {
      bloc.add(
        UpdateNote(
          id: widget.note!.id,
          title: resolvedTitle,
          content: _contentCtrl.text.trimRight(),
          colorValue: _selectedColor,
          tags: joinedTags,
          isPinned: _isPinned,
        ),
      );
    } else {
      bloc.add(
        AddNote(
          title: resolvedTitle,
          content: _contentCtrl.text.trimRight(),
          colorValue: _selectedColor,
          tags: joinedTags,
          isPinned: _isPinned,
        ),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final accentColor = Color(_selectedColor);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final trimmedContent = _contentCtrl.text.trim();
    final wordCount = trimmedContent.isEmpty
        ? 0
        : trimmedContent.split(RegExp(r'\s+')).length;

    final allTagChoices = <String>{
      ...widget.suggestedTags,
      ..._activeTags,
    }.toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.sm,
            AppSpacing.pageGutter,
            bottomInset + AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: AppRadius.topXl,
            border: Border.all(color: palette.divider),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Drag Handle ──────────────────────────────────────────────
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.divider,
                      borderRadius: AppRadius.radiusFull,
                    ),
                  ),
                ),
                AppSpacing.gapH12,

                // ── 1. Header Row ────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(
                          alpha: palette.isDark ? 0.22 : 0.14,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isEditing
                            ? Icons.edit_note_rounded
                            : Icons.note_add_outlined,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Edit Note' : 'Create New Note',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: palette.heading,
                            ),
                          ),
                          Text(
                            '$wordCount ${wordCount == 1 ? 'word' : 'words'} · ${_contentCtrl.text.length} chars',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              color: palette.caption,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tooltip(
                      message: _isPinned ? 'Pinned to top' : 'Pin to top',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isPinned = !_isPinned);
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _isPinned
                                ? accentColor.withValues(alpha: 0.15)
                                : palette.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isPinned ? accentColor : palette.divider,
                            ),
                          ),
                          child: Icon(
                            _isPinned
                                ? Icons.push_pin_rounded
                                : Icons.push_pin_outlined,
                            size: 16,
                            color: _isPinned ? accentColor : palette.icon,
                          ),
                        ),
                      ),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: 'Delete note',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _confirmDelete,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              size: 17,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: palette.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: palette.icon,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── 2. Color Accent Swatch Row ───────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        'Color Accent: ',
                        style: textTheme.labelMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.secondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      for (final colorVal in widget.colorPalette)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedColor = colorVal);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: Color(colorVal),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedColor == colorVal
                                      ? palette.heading
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: _selectedColor == colorVal
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── 3. Unified Editorial Writing Canvas ──────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted.withValues(
                      alpha: palette.isDark ? 0.40 : 0.58,
                    ),
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(
                      color: _validationError != null
                          ? AppColors.error
                          : palette.divider,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title input
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                        child: TextField(
                          controller: _titleCtrl,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (_) {
                            if (_validationError != null) {
                              setState(() => _validationError = null);
                            }
                          },
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.25,
                            color: palette.heading,
                          ),
                          decoration: InputDecoration(
                            filled: false,
                            isDense: true,
                            hintText: 'Note Title...',
                            hintStyle: textTheme.titleMedium?.copyWith(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w600,
                              color: palette.caption,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: palette.divider),

                      // Formatting toolbar strip
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _ComposerFormatChip(
                                icon: Icons.check_box_outlined,
                                label: 'Checklist',
                                accentColor: accentColor,
                                onTap: () => _insertFormatting('[ ] '),
                              ),
                              const SizedBox(width: 4),
                              _ComposerFormatChip(
                                icon: Icons.format_list_bulleted_rounded,
                                label: 'Bullet',
                                accentColor: accentColor,
                                onTap: () => _insertFormatting('• '),
                              ),
                              const SizedBox(width: 4),
                              _ComposerFormatChip(
                                icon: Icons.title_rounded,
                                label: 'Heading',
                                accentColor: accentColor,
                                onTap: () => _insertFormatting('## '),
                              ),
                              const SizedBox(width: 4),
                              _ComposerFormatChip(
                                icon: Icons.horizontal_rule_rounded,
                                label: 'Divider',
                                accentColor: accentColor,
                                onTap: () =>
                                    _insertFormatting('──────────────\n'),
                              ),
                              const SizedBox(width: 4),
                              _ComposerFormatChip(
                                icon: Icons.schedule_rounded,
                                label: 'Timestamp',
                                accentColor: accentColor,
                                onTap: () {
                                  final stamp = DateFormat(
                                    'd MMM, h:mm a',
                                  ).format(DateTime.now());
                                  _insertFormatting('[$stamp] ');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: palette.divider),

                      // Content body input
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
                        child: TextField(
                          controller: _contentCtrl,
                          focusNode: _contentFocusNode,
                          minLines: 5,
                          maxLines: 10,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (_) {
                            setState(() => _validationError = null);
                          },
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            height: 1.5,
                            color: palette.heading,
                          ),
                          decoration: InputDecoration(
                            filled: false,
                            isDense: true,
                            hintText:
                                'Write your thoughts, checklists, or plans...',
                            hintStyle: textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              height: 1.5,
                              color: palette.caption,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_validationError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _validationError!,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // ── 4. @Tag Context Bundling ─────────────────────────────────
                Text(
                  'Context Tags',
                  style: textTheme.labelMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: palette.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: allTagChoices.map((tag) {
                    final selected = _activeTags.contains(tag);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (selected) {
                            _activeTags.remove(tag);
                          } else {
                            _activeTags.add(tag);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? accentColor.withValues(
                                  alpha: palette.isDark ? 0.22 : 0.14,
                                )
                              : palette.surfaceMuted,
                          borderRadius: AppRadius.radiusFull,
                          border: Border.all(
                            color: selected ? accentColor : palette.divider,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selected) ...[
                              Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: accentColor,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              tag,
                              style: textTheme.labelSmall?.copyWith(
                                fontSize: 11.5,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: selected ? accentColor : palette.body,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),

                // Custom @tag input
                Container(
                  height: 38,
                  padding: const EdgeInsets.only(left: 12, right: 5),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted.withValues(
                      alpha: palette.isDark ? 0.40 : 0.58,
                    ),
                    borderRadius: AppRadius.radiusSm,
                    border: Border.all(color: palette.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tag_rounded, size: 15, color: palette.caption),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _customTagCtrl,
                          onSubmitted: (_) => _addCustomTag(),
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 12.5,
                            color: palette.heading,
                          ),
                          decoration: InputDecoration(
                            filled: false,
                            isDense: true,
                            hintText: 'Add custom @tag...',
                            hintStyle: textTheme.bodySmall?.copyWith(
                              fontSize: 12.5,
                              color: palette.caption,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _addCustomTag,
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          foregroundColor: accentColor,
                        ),
                        child: Text(
                          'Add Tag',
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── 5. Primary Submit Action ─────────────────────────────────
                SizedBox(
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      _isEditing ? Icons.check_rounded : Icons.add_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _isEditing ? 'Save Changes' : 'Create Note',
                      style: AppTextStyles.buttonText.copyWith(
                        color: Colors.white,
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
}

class _ComposerFormatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _ComposerFormatChip({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13.5, color: accentColor),
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
