import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/widgets/app_dropdown_menu.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/expandable_text_widget.dart';
import '../../../../core/widgets/feature_scaffold.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../money/domain/entities/money_category.dart';
import '../../../money/domain/usecases/manage_transactions_usecase.dart';
import '../../../quick_capture/presentation/widgets/quick_capture_sheet.dart';
import '../../../../di/injection_container.dart';
import '../../domain/entities/note_entity.dart';
import '../bloc/notes_bloc.dart';

enum _NoteSortOrder { updatedDesc, titleAsc }

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotesBloc>()..add(const LoadNotes()),
      child: const _NotesView(),
    );
  }
}

class _NotesView extends StatefulWidget {
  const _NotesView();

  @override
  State<_NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<_NotesView> {
  static const _scratchpadPrefKey = 'daily_scratchpad_content';

  final TextEditingController _scratchpadController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedTag = 'All';
  String _searchQuery = '';
  bool _isGridView = false;
  _NoteSortOrder _sortOrder = _NoteSortOrder.updatedDesc;

  // Curated design-system accent colors for notes (zero raw hex literals)
  static final List<int> _notePalette = <int>[
    AppColors.moduleTime.toARGB32(),
    AppColors.moduleMoney.toARGB32(),
    AppColors.moneyCatTransport.toARGB32(),
    AppColors.moduleVault.toARGB32(),
    AppColors.moneyAssetSavings.toARGB32(),
    AppColors.moneyCatBills.toARGB32(),
  ];

  static const List<String> _suggestedTags = [
    '@Ideas',
    '@Work',
    '@Personal',
    '@Shopping',
    '@Finance',
    '@Tasks',
  ];

  @override
  void initState() {
    super.initState();
    _loadScratchpad();
  }

  @override
  void dispose() {
    _scratchpadController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadScratchpad() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_scratchpadPrefKey);
      if (saved != null && !saved.contains('Locksmith phone')) {
        _scratchpadController.text = saved;
      } else if (saved != null && saved.contains('Locksmith phone')) {
        await prefs.remove(_scratchpadPrefKey);
        _scratchpadController.text = '';
      } else {
        _scratchpadController.text = '';
      }
    } catch (_) {
      _scratchpadController.text = '';
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveScratchpad(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_scratchpadPrefKey, value);
    } catch (_) {}
  }

  void _saveScratchpadAsNote(BuildContext context) {
    final text = _scratchpadController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scratchpad is empty! Type something first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final lines = text.split('\n');
    final title = lines.first.length > 40
        ? '${lines.first.substring(0, 40)}...'
        : lines.first;
    final content = lines.length > 1 ? lines.sublist(1).join('\n') : text;

    context.read<NotesBloc>().add(
      AddNote(
        title: title.isEmpty ? 'Scratchpad Note' : title,
        content: content,
        colorValue: _notePalette.first,
        tags: '@Scratchpad',
      ),
    );

    _scratchpadController.clear();
    _saveScratchpad('');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved scratchpad as a new note!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _clearScratchpad(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Clear Scratchpad?',
      message:
          'Are you sure you want to erase the scratchpad? This cannot be undone.',
      confirmLabel: 'Clear',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      _scratchpadController.clear();
      await _saveScratchpad('');
      setState(() {});
    }
  }

  void _toggleChecklistLine(
    BuildContext context,
    NoteEntity note,
    int lineIndex,
  ) {
    final lines = note.content.split('\n');
    if (lineIndex < 0 || lineIndex >= lines.length) return;
    final raw = lines[lineIndex];
    final trimmed = raw.trimLeft();
    final indent = raw.substring(0, raw.length - trimmed.length);

    if (trimmed.startsWith('[ ] ')) {
      lines[lineIndex] = '$indent[x] ${trimmed.substring(4)}';
    } else if (trimmed.startsWith('[x] ') || trimmed.startsWith('[X] ')) {
      lines[lineIndex] = '$indent[ ] ${trimmed.substring(4)}';
    } else {
      return;
    }

    HapticFeedback.selectionClick();
    context.read<NotesBloc>().add(
      UpdateNote(
        id: note.id,
        title: note.title,
        content: lines.join('\n'),
        colorValue: note.colorValue,
        tags: note.tags.join(','),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotesBloc, NotesState>(
      builder: (context, state) => FeatureScaffold(
        title: StringConstants.navNotes,
        accentColor: AppColors.moduleNotes,
        actionsEndPadding: AppSpacing.pageGutter,
        status: switch (state) {
          NotesLoaded() => FeatureStatus.content,
          NotesError() => FeatureStatus.error,
          _ => FeatureStatus.loading,
        },
        errorMessage: state is NotesError ? state.message : null,
        onRetry: () => context.read<NotesBloc>().add(const LoadNotes()),
        loading: const FeatureLoadingView(
          blockHeights: [44, 112, 36, 128, 128],
        ),
        builder: (_) => _buildContent(context, state as NotesLoaded),
        actions: [
          FeatureIconButton(
            tooltip: 'Camera OCR Scan',
            icon: Icons.document_scanner_outlined,
            color: context.palette.icon,
            onPressed: () async {
              await QuickCaptureSheet.show(
                context,
                mode: QuickCaptureMode.scan,
              );
              if (context.mounted) {
                context.read<NotesBloc>().add(const LoadNotes());
              }
            },
          ),
          AppSpacing.gapW8,
          FeatureIconButton(
            tooltip: 'Voice Note',
            icon: Icons.mic_none_rounded,
            color: AppColors.voiceWaveform,
            onPressed: () async {
              await QuickCaptureSheet.show(
                context,
                mode: QuickCaptureMode.voice,
              );
              if (context.mounted) {
                context.read<NotesBloc>().add(const LoadNotes());
              }
            },
          ),
          AppSpacing.gapW8,
          FeatureHeaderButton(
            icon: Icons.add_rounded,
            label: 'New Note',
            color: AppColors.moduleNotes,
            onPressed: () => _showNoteEditor(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, NotesLoaded state) {
    final tagCounts = <String, int>{'All': state.notes.length};
    for (final note in state.notes) {
      for (final tag in note.tags) {
        if (tag.isNotEmpty) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
    }
    final allTags = tagCounts.keys.toList();

    final query = _searchQuery.trim().toLowerCase();
    final filteredNotes = state.notes.where((note) {
      final matchesTag =
          _selectedTag == 'All' || note.tags.contains(_selectedTag);
      final matchesSearch =
          query.isEmpty ||
          note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query) ||
          note.tags.any((t) => t.toLowerCase().contains(query));
      return matchesTag && matchesSearch;
    }).toList();

    if (_sortOrder == _NoteSortOrder.titleAsc) {
      filteredNotes.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    } else {
      filteredNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    final pinnedNotes = filteredNotes.where((n) => n.isPinned).toList();
    final unpinnedNotes = filteredNotes.where((n) => !n.isPinned).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.xs,
        AppSpacing.pageGutter,
        AppSpacing.huge * 2,
      ),
      children: [
        // ── 1. Search Bar + Layout & Sort Controls ─────────────────────────
        _buildSearchAndControlBar(context),
        AppSpacing.gapH12,

        // ── 2. Elevated Daily Scratchpad Card ──────────────────────────────
        _buildScratchpadCard(context),
        AppSpacing.gapH16,

        // ── 3. Tag Filter Strip with Counts ────────────────────────────────
        if (allTags.length > 1) ...[
          SizedBox(
            height: AppSpacing.xxl + AppSpacing.xxs,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: allTags.length,
              separatorBuilder: (_, _) => AppSpacing.gapW8,
              itemBuilder: (context, index) {
                final tag = allTags[index];
                return _buildTagChip(context, tag, tagCounts[tag] ?? 0);
              },
            ),
          ),
          AppSpacing.gapH16,
        ],

        // ── 4. Empty State or Note Cards (List / 2-Column Bento Grid) ──────
        if (filteredNotes.isEmpty)
          _buildEmptyNotesState(context)
        else ...[
          if (pinnedNotes.isNotEmpty) ...[
            _buildSectionHeader(
              context: context,
              icon: Icons.push_pin_rounded,
              iconColor: AppColors.moduleNotes,
              label: 'PINNED (${pinnedNotes.length})',
            ),
            AppSpacing.gapH8,
            _buildNotesCollection(context, pinnedNotes),
            AppSpacing.gapH16,
          ],
          if (unpinnedNotes.isNotEmpty) ...[
            if (pinnedNotes.isNotEmpty) ...[
              _buildSectionHeader(
                context: context,
                icon: Icons.notes_rounded,
                iconColor: context.palette.caption,
                label: 'ALL NOTES (${unpinnedNotes.length})',
              ),
              AppSpacing.gapH8,
            ],
            _buildNotesCollection(context, unpinnedNotes),
          ],
        ],
      ],
    );
  }

  Widget _buildNotesCollection(BuildContext context, List<NoteEntity> notes) {
    if (!_isGridView) {
      return Column(
        children: notes
            .map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _buildNoteCard(context, note, isCompactGrid: false),
              ),
            )
            .toList(),
      );
    }

    // 2-Column Bento Grid View (pairs of cards side-by-side)
    final rows = <Widget>[];
    for (var i = 0; i < notes.length; i += 2) {
      final first = notes[i];
      final second = (i + 1 < notes.length) ? notes[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildNoteCard(context, first, isCompactGrid: true),
              ),
              AppSpacing.gapW12,
              Expanded(
                child: second != null
                    ? _buildNoteCard(context, second, isCompactGrid: true)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: AppSpacing.md, color: iconColor),
        AppSpacing.gapW8,
        Text(
          label,
          style: context.text.labelSmall?.copyWith(
            color: context.palette.caption,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ── 1. Search Bar + Layout & Sort Controls ─────────────────────────────────
  Widget _buildSearchAndControlBar(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: AppSpacing.xxxl + AppSpacing.xxs,
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: palette.border),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: context.text.bodyMedium?.copyWith(color: palette.heading),
              decoration: InputDecoration(
                filled: false,
                isDense: true,
                hintText: 'Search notes, tags, or content...',
                hintStyle: context.text.bodyMedium?.copyWith(
                  color: palette.caption,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: palette.icon,
                  size: AppSpacing.lg,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: AppSpacing.xxxl,
                  minHeight: AppSpacing.xxxl,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          size: AppSpacing.md,
                          color: palette.caption,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),
        ),
        AppSpacing.gapW8,
        Tooltip(
          message: _sortOrder == _NoteSortOrder.updatedDesc
              ? 'Sorted by recent'
              : 'Sorted A–Z',
          child: InkWell(
            key: const ValueKey('toggle_notes_sort'),
            borderRadius: AppRadius.borderMd,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _sortOrder = _sortOrder == _NoteSortOrder.updatedDesc
                    ? _NoteSortOrder.titleAsc
                    : _NoteSortOrder.updatedDesc;
              });
            },
            child: Container(
              width: AppSpacing.xxxl + AppSpacing.xxs,
              height: AppSpacing.xxxl + AppSpacing.xxs,
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: AppRadius.borderMd,
                border: Border.all(color: palette.border),
              ),
              child: Icon(
                _sortOrder == _NoteSortOrder.updatedDesc
                    ? Icons.swap_vert_rounded
                    : Icons.sort_by_alpha_rounded,
                size: AppSpacing.lg,
                color: _sortOrder == _NoteSortOrder.titleAsc
                    ? AppColors.moduleNotes
                    : palette.icon,
              ),
            ),
          ),
        ),
        AppSpacing.gapW8,
        Tooltip(
          message: _isGridView ? 'Switch to List view' : 'Switch to Grid view',
          child: InkWell(
            key: const ValueKey('toggle_notes_view_mode'),
            borderRadius: AppRadius.borderMd,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isGridView = !_isGridView);
            },
            child: Container(
              width: AppSpacing.xxxl + AppSpacing.xxs,
              height: AppSpacing.xxxl + AppSpacing.xxs,
              decoration: BoxDecoration(
                color: _isGridView
                    ? AppColors.moduleNotes.withValues(alpha: 0.14)
                    : palette.card,
                borderRadius: AppRadius.borderMd,
                border: Border.all(
                  color: _isGridView ? AppColors.moduleNotes : palette.border,
                ),
              ),
              child: Icon(
                _isGridView
                    ? Icons.view_agenda_outlined
                    : Icons.grid_view_rounded,
                size: AppSpacing.lg,
                color: _isGridView ? AppColors.moduleNotes : palette.icon,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 2. Elevated Daily Scratchpad Card ──────────────────────────────────────
  Widget _buildScratchpadCard(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: AppSpacing.edgeInsetsAllMd,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: AppColors.moduleNotes.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: AppSpacing.xl + AppSpacing.xxs,
                    height: AppSpacing.xl + AppSpacing.xxs,
                    decoration: BoxDecoration(
                      color: AppColors.moduleNotes.withValues(alpha: 0.14),
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.moduleNotes,
                      size: AppSpacing.md,
                    ),
                  ),
                  AppSpacing.gapW8,
                  Text(
                    StringConstants.dailyScratchpad.toUpperCase(),
                    style: context.text.labelSmall?.copyWith(
                      color: AppColors.moduleNotes,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _scratchpadController,
                builder: (context, value, _) {
                  final hasText = value.text.trim().isNotEmpty;
                  if (!hasText) {
                    return Text(
                      'Instant auto-save',
                      style: context.text.labelSmall?.copyWith(
                        color: palette.caption,
                      ),
                    );
                  }
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        borderRadius: AppRadius.radiusSm,
                        onTap: () => _saveScratchpadAsNote(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.moduleNotes,
                            borderRadius: AppRadius.radiusSm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bookmark_add_outlined,
                                size: AppSpacing.sm + AppSpacing.xxxs,
                                color: AppColors.textWhite,
                              ),
                              AppSpacing.gapW4,
                              Text(
                                StringConstants.save,
                                style: context.text.labelMedium?.copyWith(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AppSpacing.gapW8,
                      InkWell(
                        borderRadius: AppRadius.radiusSm,
                        onTap: () => _clearScratchpad(context),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxs),
                          child: Icon(
                            Icons.close_rounded,
                            size: AppSpacing.md,
                            color: palette.caption,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          AppSpacing.gapH12,
          TextField(
            controller: _scratchpadController,
            onChanged: _saveScratchpad,
            minLines: 2,
            maxLines: 4,
            style: context.text.bodyMedium?.copyWith(color: palette.heading),
            decoration: InputDecoration(
              filled: false,
              isDense: true,
              hintText: StringConstants.scratchpadHint,
              hintStyle: context.text.bodyMedium?.copyWith(
                color: palette.caption,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: AppSpacing.edgeInsetsZero,
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Tag Filter Chip with Count Badge ────────────────────────────────────
  Widget _buildTagChip(BuildContext context, String tag, int count) {
    final isSelected = _selectedTag == tag;
    final palette = context.palette;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTag = tag);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs + AppSpacing.xxxs,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.moduleNotes : palette.card,
          borderRadius: AppRadius.radiusFull,
          border: Border.all(
            color: isSelected ? AppColors.moduleNotes : palette.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag,
              style: context.text.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.textWhite : palette.body,
              ),
            ),
            AppSpacing.gapW4,
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxs + AppSpacing.xxxs,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.textWhite.withValues(alpha: 0.22)
                    : palette.surfaceMuted,
                borderRadius: AppRadius.radiusFull,
              ),
              child: Text(
                '$count',
                style: context.text.labelSmall?.copyWith(
                  color: isSelected ? AppColors.textWhite : palette.caption,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. Empty Notes State ───────────────────────────────────────────────────
  Widget _buildEmptyNotesState(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: AppSpacing.edgeInsetsAllXl,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: palette.border),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: AppSpacing.huge,
            height: AppSpacing.huge,
            decoration: BoxDecoration(
              color: AppColors.moduleNotes.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.note_alt_outlined,
              size: AppSpacing.xl,
              color: AppColors.moduleNotes,
            ),
          ),
          AppSpacing.gapH12,
          Text(
            _searchQuery.isNotEmpty
                ? 'No notes match "$_searchQuery"'
                : 'No notes in this view',
            style: context.text.titleMedium?.copyWith(color: palette.heading),
          ),
          AppSpacing.gapH4,
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different keyword or clear the filter.'
                : 'Tap "New Note" above or jot in the scratchpad.',
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: palette.secondary),
          ),
          if (_searchQuery.isNotEmpty || _selectedTag != 'All') ...[
            AppSpacing.gapH16,
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedTag = 'All';
                });
              },
              child: const Text('Clear Filter'),
            ),
          ],
        ],
      ),
    );
  }

  // ── 5. Craft-Grade Note Card (List & Grid Modes + Interactive Checklists) ──
  Widget _buildNoteCard(
    BuildContext context,
    NoteEntity note, {
    required bool isCompactGrid,
  }) {
    final palette = context.palette;
    final noteColor = note.color;
    final allLines = note.content.split('\n');
    final checklistIndices = <int>[];
    final proseLines = <String>[];

    for (var i = 0; i < allLines.length; i++) {
      final trimmed = allLines[i].trimLeft();
      if (trimmed.startsWith('[ ] ') ||
          trimmed.startsWith('[x] ') ||
          trimmed.startsWith('[X] ')) {
        checklistIndices.add(i);
      } else if (trimmed.isNotEmpty) {
        proseLines.add(allLines[i]);
      }
    }

    final prosePreview = proseLines.join('\n').trim();

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: note.isPinned
              ? noteColor.withValues(alpha: 0.55)
              : palette.border,
          width: note.isPinned ? 1.2 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderLg,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: noteColor, width: AppSpacing.xxs),
            ),
          ),
          child: InkWell(
            onTap: () => _showNoteEditor(context, note: note),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md + AppSpacing.xxs,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Title + Pin + More Actions Menu
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: AppSpacing.xs,
                            height: AppSpacing.xs,
                            decoration: BoxDecoration(
                              color: noteColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          AppSpacing.gapW8,
                          Expanded(
                            child: ExpandableTextWidget(
                              text: note.title,
                              collapsedMaxLines: 2,
                              characterThreshold: 45,
                              toggleColor: noteColor,
                              style:
                                  (isCompactGrid
                                          ? context.text.titleSmall
                                          : context.text.titleMedium)
                                      ?.copyWith(
                                        color: palette.heading,
                                        fontWeight: FontWeight.w700,
                                      ),
                            ),
                          ),
                          AppSpacing.gapW4,
                          Tooltip(
                            message: note.isPinned ? 'Unpin' : 'Pin note',
                            child: InkWell(
                              borderRadius: AppRadius.radiusSm,
                              onTap: () => context.read<NotesBloc>().add(
                                TogglePinNote(note.id),
                              ),
                              child: SizedBox(
                                width: AppSpacing.xl + AppSpacing.xxs,
                                height: AppSpacing.xl + AppSpacing.xxs,
                                child: Icon(
                                  note.isPinned
                                      ? Icons.push_pin_rounded
                                      : Icons.push_pin_outlined,
                                  size: AppSpacing.md,
                                  color: note.isPinned
                                      ? noteColor
                                      : palette.caption,
                                ),
                              ),
                            ),
                          ),
                          _buildCardDropdownMenu(context, note),
                        ],
                      ),

                      // Prose Preview with ExpandableTextWidget
                      if (prosePreview.isNotEmpty) ...[
                        AppSpacing.gapH8,
                        ExpandableTextWidget(
                          text: prosePreview,
                          collapsedMaxLines: isCompactGrid ? 3 : 3,
                          toggleColor: noteColor,
                          style: context.text.bodyMedium?.copyWith(
                            color: palette.body,
                          ),
                        ),
                      ],

                      // Interactive Inline Checklists + Completion Progress Bar
                      if (checklistIndices.isNotEmpty) ...[
                        AppSpacing.gapH8,
                        Builder(
                          builder: (context) {
                            final doneCount = checklistIndices.where((idx) {
                              final raw = allLines[idx].trimLeft();
                              return raw.startsWith('[x] ') ||
                                  raw.startsWith('[X] ');
                            }).length;
                            final totalCount = checklistIndices.length;
                            final pct = totalCount > 0
                                ? (doneCount / totalCount).clamp(0.0, 1.0)
                                : 0.0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: AppRadius.radiusFull,
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween<double>(
                                          begin: 0,
                                          end: pct,
                                        ),
                                        duration: const Duration(
                                          milliseconds: 420,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, val, _) =>
                                            LinearProgressIndicator(
                                              value: val,
                                              minHeight: 4,
                                              backgroundColor:
                                                  palette.surfaceMuted,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    noteColor,
                                                  ),
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$doneCount/$totalCount',
                                    style: context.text.labelSmall?.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: noteColor,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        ...checklistIndices.take(isCompactGrid ? 3 : 4).map((
                          lineIdx,
                        ) {
                          final rawLine = allLines[lineIdx].trimLeft();
                          final isChecked =
                              rawLine.startsWith('[x] ') ||
                              rawLine.startsWith('[X] ');
                          final itemText = rawLine.substring(4);
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xxs,
                            ),
                            child: InkWell(
                              borderRadius: AppRadius.radiusXs,
                              onTap: () =>
                                  _toggleChecklistLine(context, note, lineIdx),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xxxs,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 1.5),
                                      child: Icon(
                                        isChecked
                                            ? Icons.check_circle_rounded
                                            : Icons
                                                  .radio_button_unchecked_rounded,
                                        size: AppSpacing.md,
                                        color: isChecked
                                            ? noteColor
                                            : palette.caption,
                                      ),
                                    ),
                                    AppSpacing.gapW8,
                                    Expanded(
                                      child: Text(
                                        itemText,
                                        softWrap: true,
                                        style: context.text.bodySmall?.copyWith(
                                          color: isChecked
                                              ? palette.caption
                                              : palette.body,
                                          decoration: isChecked
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSpacing.gapH12,
                      // Footer: Tags + Updated Date + Convert to Planner Pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xxs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  _formatShortDate(note.updatedAt),
                                  style: context.text.labelSmall?.copyWith(
                                    color: palette.caption,
                                  ),
                                ),
                                ...note.tags
                                    .take(isCompactGrid ? 1 : 3)
                                    .map(
                                      (tag) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.xs,
                                          vertical: AppSpacing.xxxs,
                                        ),
                                        decoration: BoxDecoration(
                                          color: noteColor.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: AppRadius.radiusXs,
                                        ),
                                        child: Text(
                                          tag,
                                          style: context.text.labelSmall
                                              ?.copyWith(
                                                color: noteColor,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                          AppSpacing.gapW8,
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildConverterButton(
                                context: context,
                                label: isCompactGrid ? 'Task' : '-> Task',
                                icon: Icons.add_task_rounded,
                                color: AppColors.moduleTime,
                                onTap: () =>
                                    _convertToPlannerTask(context, note),
                              ),
                              if (!isCompactGrid) ...[
                                AppSpacing.gapW4,
                                _buildConverterButton(
                                  context: context,
                                  label: '-> Expense',
                                  icon: Icons.payments_outlined,
                                  color: AppColors.moduleMoney,
                                  onTap: () => _convertToExpense(context, note),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatShortDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return DateFormat('d MMM').format(dt);
  }

  // ── Card Dropdown Popup Menu ───────────────────────────────────────────────
  Widget _buildCardDropdownMenu(BuildContext context, NoteEntity note) {
    final palette = context.palette;

    return AppDropdownMenu<String>(
      tooltip: 'Note actions',
      icon: Icon(
        Icons.more_horiz_rounded,
        size: AppSpacing.lg,
        color: palette.caption,
      ),
      onSelected: (action) {
        switch (action) {
          case 'edit':
            _showNoteEditor(context, note: note);
            break;
          case 'pin':
            context.read<NotesBloc>().add(TogglePinNote(note.id));
            break;
          case 'copy':
            _copyToClipboard(context, note);
            break;
          case 'convert_task':
            _convertToPlannerTask(context, note);
            break;
          case 'convert_expense':
            _convertToExpense(context, note);
            break;
          case 'delete':
            _deleteNoteWithConfirmation(context, note);
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

  // ── Converter Button Pill ──────────────────────────────────────────────────
  Widget _buildConverterButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: AppRadius.radiusXs,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadius.radiusXs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSpacing.sm, color: color),
            AppSpacing.gapW4,
            Text(
              label,
              style: context.text.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions: Copy to Clipboard ─────────────────────────────────────────────
  void _copyToClipboard(BuildContext context, NoteEntity note) {
    final text = '${note.title}\n\n${note.content}';
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Actions: Convert Note to Task in Planner (Actual SQLite Insert) ────────
  Future<void> _convertToPlannerTask(
    BuildContext context,
    NoteEntity note,
  ) async {
    try {
      final db = sl<AppDatabase>();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final taskTitle = note.title.isNotEmpty
          ? note.title
          : 'Reminder from note';

      await db
          .into(db.plannerItems)
          .insert(
            PlannerItemsCompanion.insert(
              title: taskTitle,
              date: today,
              startTime: const Value('09:00 AM'),
              category: 'Notes',
              colorValue: AppColors.moduleTime.toARGB32(),
              iconCodePoint: Icons.event_note_rounded.codePoint,
              notes: Value(note.content),
            ),
          );

      if (context.mounted) {
        SnackbarUtils.showSuccess(
          context,
          '${StringConstants.convertedToReminderMessage}: "$taskTitle"',
        );
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarUtils.showError(context, 'Could not convert to task: $e');
      }
    }
  }

  // ── Actions: Convert Note to Expense in Money ──────────────────────────────
  Future<void> _convertToExpense(BuildContext context, NoteEntity note) async {
    final combined = '${note.title} ${note.content}';
    final match = RegExp(r'(\d+(?:\.\d{1,2})?)').firstMatch(combined);
    final initialAmount = match?.group(1) ?? '';

    final titleCtrl = TextEditingController(
      text: note.title.isNotEmpty ? note.title : 'Note Expense',
    );
    final amountCtrl = TextEditingController(text: initialAmount);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(StringConstants.convertToExpense),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: StringConstants.merchantLabel,
              ),
            ),
            AppSpacing.gapH12,
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: StringConstants.amountLabel,
                prefixText: '${CurrencyUtils.symbol} ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(StringConstants.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.moduleMoney,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(StringConstants.save),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      SnackbarUtils.showError(context, StringConstants.invalidAmount);
      return;
    }

    try {
      final title = titleCtrl.text.trim().isNotEmpty
          ? titleCtrl.text.trim()
          : 'Note Expense';
      if (sl.isRegistered<AddTransactionUseCase>()) {
        await sl<AddTransactionUseCase>()(
          title: title,
          category: MoneyCategory.other.key,
          amount: amount,
          mode: StringConstants.paymentModeUPI,
          iconCodePoint: MoneyCategory.other.icon.codePoint,
          type: 'expense',
          date: DateTime.now(),
          note: note.content,
        );
      }
      if (context.mounted) {
        SnackbarUtils.showSuccess(
          context,
          '${StringConstants.convertedToExpenseMessage}: $title (${CurrencyUtils.format(amount)})',
        );
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarUtils.showError(context, '$e');
      }
    }
  }

  // ── Actions: Delete Note with Confirmation ─────────────────────────────────
  Future<void> _deleteNoteWithConfirmation(
    BuildContext context,
    NoteEntity note,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Note?',
      message:
          'Are you sure you want to delete "${note.title}"? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      context.read<NotesBloc>().add(DeleteNote(note.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Redesigned Note Editor Modal Sheet (Create & Edit) ─────────────────────
  void _showNoteEditor(BuildContext context, {NoteEntity? note}) {
    final notesBloc = context.read<NotesBloc>();
    final isEditing = note != null;
    final titleCtrl = TextEditingController(text: note?.title ?? '');
    final contentCtrl = TextEditingController(text: note?.content ?? '');
    final customTagCtrl = TextEditingController();

    int selectedColor = note?.colorValue ?? _notePalette.first;
    final List<String> activeTags = note != null
        ? List<String>.from(note.tags)
        : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: notesBloc,
          child: StatefulBuilder(
            builder: (sheetStateContext, setSheetState) {
              final palette = sheetStateContext.palette;
              final textTheme = sheetStateContext.text;
              final accentColor = Color(selectedColor);

              final rawContent = contentCtrl.text.trim();
              final wordCount = rawContent.isEmpty
                  ? 0
                  : rawContent.split(RegExp(r'\s+')).length;

              return Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  left: AppSpacing.pageGutter,
                  right: AppSpacing.pageGutter,
                  top: AppSpacing.sm,
                  bottom:
                      MediaQuery.of(sheetContext).viewInsets.bottom +
                      AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: AppRadius.topXl,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: AppSpacing.xxl,
                          height: AppSpacing.xxs,
                          decoration: BoxDecoration(
                            color: palette.divider,
                            borderRadius: AppRadius.radiusFull,
                          ),
                        ),
                      ),
                      AppSpacing.gapH12,

                      // Header Row: Title + Word Count + Delete/Close
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing ? 'Edit Note' : 'Create New Note',
                                  style: textTheme.headlineSmall?.copyWith(
                                    color: palette.heading,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                AppSpacing.gapH4,
                                Text(
                                  '$wordCount words · ${contentCtrl.text.length} chars',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: palette.caption,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isEditing)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: AppSpacing.lg,
                                    color: AppColors.error,
                                  ),
                                  tooltip: 'Delete Note',
                                  onPressed: () async {
                                    final confirmed = await ConfirmationDialog.show(
                                      sheetContext,
                                      title: 'Delete Note?',
                                      message:
                                          'Are you sure you want to delete "${note.title}"?',
                                      confirmLabel: 'Delete',
                                      isDestructive: true,
                                    );
                                    if (confirmed == true &&
                                        sheetContext.mounted) {
                                      Navigator.of(sheetContext).pop();
                                      notesBloc.add(DeleteNote(note.id));
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Note deleted.'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: AppSpacing.lg,
                                  color: palette.icon,
                                ),
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      AppSpacing.gapH12,

                      // Title Input (borderless filled: false with accent underline)
                      TextField(
                        controller: titleCtrl,
                        style: textTheme.titleLarge?.copyWith(
                          color: palette.heading,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          filled: false,
                          isDense: true,
                          hintText: 'Note Title...',
                          hintStyle: textTheme.titleLarge?.copyWith(
                            color: palette.caption,
                            fontWeight: FontWeight.w600,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: accentColor,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: accentColor.withValues(alpha: 0.55),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: accentColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.gapH16,

                      // Color Palette Selector
                      Row(
                        children: [
                          Text(
                            'Color Accent: ',
                            style: textTheme.labelMedium?.copyWith(
                              color: palette.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          AppSpacing.gapW8,
                          Expanded(
                            child: Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: _notePalette.map((colorVal) {
                                final isSelected = selectedColor == colorVal;
                                final swatchColor = Color(colorVal);
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setSheetState(
                                      () => selectedColor = colorVal,
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    width: AppSpacing.xl + AppSpacing.xxs,
                                    height: AppSpacing.xl + AppSpacing.xxs,
                                    decoration: BoxDecoration(
                                      color: swatchColor,
                                      shape: BoxShape.circle,
                                      border: isSelected
                                          ? Border.all(
                                              color: palette.heading,
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check_rounded,
                                            size: AppSpacing.md,
                                            color: AppColors.textWhite,
                                          )
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapH16,

                      // Formatting Shortcut Toolbar
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildEditorHelperChip(
                              context: sheetStateContext,
                              icon: Icons.format_list_bulleted_rounded,
                              label: 'Bullet',
                              onTap: () {
                                final text = contentCtrl.text;
                                final selection = contentCtrl.selection;
                                const bullet = '\n• ';
                                final newText = text.isEmpty
                                    ? '• '
                                    : text.replaceRange(
                                        selection.start >= 0
                                            ? selection.start
                                            : text.length,
                                        selection.end >= 0
                                            ? selection.end
                                            : text.length,
                                        bullet,
                                      );
                                setSheetState(() => contentCtrl.text = newText);
                              },
                            ),
                            AppSpacing.gapW8,
                            _buildEditorHelperChip(
                              context: sheetStateContext,
                              icon: Icons.check_box_outline_blank_rounded,
                              label: 'Checklist',
                              onTap: () {
                                final text = contentCtrl.text;
                                final selection = contentCtrl.selection;
                                const todo = '\n[ ] ';
                                final newText = text.isEmpty
                                    ? '[ ] '
                                    : text.replaceRange(
                                        selection.start >= 0
                                            ? selection.start
                                            : text.length,
                                        selection.end >= 0
                                            ? selection.end
                                            : text.length,
                                        todo,
                                      );
                                setSheetState(() => contentCtrl.text = newText);
                              },
                            ),
                            AppSpacing.gapW8,
                            _buildEditorHelperChip(
                              context: sheetStateContext,
                              icon: Icons.calendar_today_rounded,
                              label: 'Date',
                              onTap: () {
                                final nowStr = DateFormat(
                                  'dd MMM, h:mm a',
                                ).format(DateTime.now());
                                final text = contentCtrl.text;
                                final selection = contentCtrl.selection;
                                final toInsert = '\n[$nowStr] ';
                                final newText = text.isEmpty
                                    ? '[$nowStr] '
                                    : text.replaceRange(
                                        selection.start >= 0
                                            ? selection.start
                                            : text.length,
                                        selection.end >= 0
                                            ? selection.end
                                            : text.length,
                                        toInsert,
                                      );
                                setSheetState(() => contentCtrl.text = newText);
                              },
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapH12,

                      // Content Input Field
                      Container(
                        padding: AppSpacing.edgeInsetsAllMd,
                        decoration: BoxDecoration(
                          color: palette.surfaceMuted,
                          borderRadius: AppRadius.borderMd,
                          border: Border.all(color: palette.border),
                        ),
                        child: TextField(
                          controller: contentCtrl,
                          onChanged: (_) => setSheetState(() {}),
                          maxLines: 6,
                          style: textTheme.bodyMedium?.copyWith(
                            color: palette.heading,
                          ),
                          decoration: InputDecoration(
                            filled: false,
                            isDense: true,
                            hintText:
                                'Write your thoughts, checklists, or plans...',
                            hintStyle: textTheme.bodyMedium?.copyWith(
                              color: palette.caption,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: AppSpacing.edgeInsetsZero,
                          ),
                        ),
                      ),
                      AppSpacing.gapH16,

                      // Quick Tag Chips
                      Text(
                        'Tags:',
                        style: textTheme.labelMedium?.copyWith(
                          color: palette.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppSpacing.gapH8,
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: _suggestedTags.map((tag) {
                          final isTagActive = activeTags.contains(tag);
                          return FilterChip(
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            selected: isTagActive,
                            label: Text(tag, style: textTheme.labelMedium),
                            selectedColor: accentColor.withValues(alpha: 0.2),
                            checkmarkColor: accentColor,
                            onSelected: (selected) {
                              setSheetState(() {
                                if (selected) {
                                  activeTags.add(tag);
                                } else {
                                  activeTags.remove(tag);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      AppSpacing.gapH12,

                      // Custom Tag Input Row
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: AppSpacing.xxxl,
                              child: TextField(
                                controller: customTagCtrl,
                                style: textTheme.bodySmall?.copyWith(
                                  color: palette.heading,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Add custom tag (e.g. @Meeting)',
                                  hintStyle: textTheme.bodySmall?.copyWith(
                                    color: palette.caption,
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs + AppSpacing.xxxs,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          AppSpacing.gapW8,
                          SizedBox(
                            height: AppSpacing.xxxl,
                            child: OutlinedButton(
                              onPressed: () {
                                final custom = customTagCtrl.text.trim();
                                if (custom.isNotEmpty) {
                                  final formatted = custom.startsWith('@')
                                      ? custom
                                      : '@$custom';
                                  if (!activeTags.contains(formatted)) {
                                    setSheetState(
                                      () => activeTags.add(formatted),
                                    );
                                  }
                                  customTagCtrl.clear();
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: AppSpacing.edgeInsetsHSm,
                                textStyle: textTheme.labelMedium,
                              ),
                              child: const Text('Add Tag'),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapH20,

                      // Save / Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: AppSpacing.huge,
                        child: FilledButton.icon(
                          onPressed: () {
                            final title = titleCtrl.text.trim();
                            final content = contentCtrl.text.trim();

                            if (title.isEmpty && content.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter a title or content.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            final effectiveTitle = title.isNotEmpty
                                ? title
                                : 'Untitled Note';
                            final tagsString = activeTags.join(',');

                            if (isEditing) {
                              notesBloc.add(
                                UpdateNote(
                                  id: note.id,
                                  title: effectiveTitle,
                                  content: content,
                                  colorValue: selectedColor,
                                  tags: tagsString,
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Note updated successfully!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              notesBloc.add(
                                AddNote(
                                  title: effectiveTitle,
                                  content: content,
                                  colorValue: selectedColor,
                                  tags: tagsString,
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Note created successfully!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }

                            Navigator.of(sheetContext).pop();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: AppColors.textWhite,
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.borderMd,
                            ),
                          ),
                          icon: const Icon(
                            Icons.check_rounded,
                            size: AppSpacing.lg,
                          ),
                          label: Text(
                            isEditing ? 'Save Changes' : 'Create Note',
                            style: AppTextStyles.buttonText.copyWith(
                              color: AppColors.textWhite,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEditorHelperChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      avatar: Icon(icon, size: AppSpacing.md, color: context.palette.icon),
      label: Text(
        label,
        style: context.text.labelMedium?.copyWith(color: context.palette.body),
      ),
      onPressed: onTap,
    );
  }
}
