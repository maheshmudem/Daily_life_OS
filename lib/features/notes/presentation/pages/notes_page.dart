import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/feature_scaffold.dart';
import '../../../../core/widgets/staggered_fade_slide.dart';
import '../../../../di/injection_container.dart';
import '../../../money/domain/usecases/manage_transactions_usecase.dart';
import '../../../quick_capture/presentation/widgets/quick_capture_sheet.dart';
import '../../domain/entities/note_entity.dart';
import '../bloc/notes_bloc.dart';
import '../widgets/note_card_widget.dart';
import '../widgets/note_editor_sheet.dart';
import '../widgets/note_expense_converter_sheet.dart';
import '../widgets/notes_scratchpad_card.dart';

enum _NoteSortOrder { updatedDesc, titleAsc, colorGroup }

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
  static const String _scratchpadPrefKey = 'daily_scratchpad_content';
  static const String _filterAll = 'All';
  static const String _filterPinned = '__pinned__';
  static const String _filterChecklists = '__checklists__';

  final TextEditingController _scratchpadController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _activeFilter = _filterAll;
  String _searchQuery = '';
  bool _isGridView = false;
  _NoteSortOrder _sortOrder = _NoteSortOrder.updatedDesc;

  static final List<int> _notePalette = <int>[
    AppColors.moduleNotes.toARGB32(),
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
      SnackbarUtils.showInfo(
        context,
        'Scratchpad is empty! Type something first.',
      );
      return;
    }

    final lines = text.split('\n');
    final firstLine = lines.first.trim();
    final title = firstLine.length > 42
        ? '${firstLine.substring(0, 42)}...'
        : firstLine;
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
    SnackbarUtils.showSuccess(context, 'Saved scratchpad as a new note!');
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

  void _cycleSortOrder() {
    HapticFeedback.selectionClick();
    setState(() {
      _sortOrder = switch (_sortOrder) {
        _NoteSortOrder.updatedDesc => _NoteSortOrder.titleAsc,
        _NoteSortOrder.titleAsc => _NoteSortOrder.colorGroup,
        _NoteSortOrder.colorGroup => _NoteSortOrder.updatedDesc,
      };
    });
  }

  String get _sortLabel => switch (_sortOrder) {
    _NoteSortOrder.updatedDesc => 'Recent first',
    _NoteSortOrder.titleAsc => 'Title A–Z',
    _NoteSortOrder.colorGroup => 'By color',
  };

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
        isPinned: note.isPinned,
      ),
    );
  }

  void _openNoteEditor(BuildContext context, {NoteEntity? note}) {
    NoteEditorSheet.show(
      context,
      note: note,
      colorPalette: _notePalette,
      suggestedTags: _suggestedTags,
    );
  }

  void _duplicateNote(BuildContext context, NoteEntity note) {
    HapticFeedback.lightImpact();
    final baseTitle = note.title.trim().isNotEmpty
        ? note.title.trim()
        : 'Untitled Note';
    context.read<NotesBloc>().add(
      AddNote(
        title: '$baseTitle (Copy)',
        content: note.content,
        colorValue: note.colorValue,
        tags: note.tags.join(','),
        isPinned: false,
      ),
    );
    SnackbarUtils.showSuccess(context, 'Duplicated "$baseTitle"');
  }

  void _copyToClipboard(BuildContext context, NoteEntity note) {
    final text = note.title.trim().isNotEmpty
        ? '${note.title.trim()}\n\n${note.content}'
        : note.content;
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    SnackbarUtils.showSuccess(context, 'Note copied to clipboard');
  }

  Future<void> _convertToPlannerTask(
    BuildContext context,
    NoteEntity note,
  ) async {
    try {
      final db = sl<AppDatabase>();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final taskTitle = note.title.trim().isNotEmpty
          ? note.title.trim()
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

  Future<void> _pushToTodayTimeline(
    BuildContext context,
    NoteEntity note,
  ) async {
    try {
      final db = sl<AppDatabase>();
      final now = DateTime.now();
      final today = now.toIso8601String().substring(0, 10);
      final formattedTime = DateFormat('hh:mm a').format(now);
      final itemTitle = note.title.trim().isNotEmpty
          ? note.title.trim()
          : 'Note Focus Item';

      await db
          .into(db.timelineItems)
          .insert(
            TimelineItemsCompanion.insert(
              time: formattedTime,
              title: itemTitle,
              category: 'Notes',
              colorValue: note.colorValue,
              iconCodePoint: Icons.sticky_note_2_outlined.codePoint,
              action: StringConstants.viewAction,
              date: today,
            ),
          );

      if (context.mounted) {
        SnackbarUtils.showSuccess(
          context,
          '${StringConstants.pushedToTimelineMessage}: "$itemTitle"',
        );
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarUtils.showError(context, 'Could not add to timeline: $e');
      }
    }
  }

  Future<void> _convertToExpense(BuildContext context, NoteEntity note) async {
    final result = await NoteExpenseConverterSheet.show(context, note: note);
    if (result == null || !context.mounted) return;

    try {
      if (sl.isRegistered<AddTransactionUseCase>()) {
        await sl<AddTransactionUseCase>()(
          title: result.title,
          category: result.category.key,
          amount: result.amount,
          mode: result.paymentMode,
          iconCodePoint: result.category.icon.codePoint,
          type: 'expense',
          date: DateTime.now(),
          note: note.content,
        );
      }
      if (context.mounted) {
        SnackbarUtils.showSuccess(
          context,
          '${StringConstants.convertedToExpenseMessage}: ${result.title} (${CurrencyUtils.format(result.amount)})',
        );
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarUtils.showError(context, '$e');
      }
    }
  }

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
      SnackbarUtils.showInfo(context, 'Note deleted');
    }
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
        onRefresh: () async {
          context.read<NotesBloc>().add(const LoadNotes());
        },
        loading: const FeatureLoadingView(
          blockHeights: [54, 118, 38, 32, 136, 136],
        ),
        builder: (_) => _buildContent(context, state as NotesLoaded),
        actions: [
          FeatureIconButton(
            tooltip: 'Camera OCR Scan',
            icon: Icons.document_scanner_outlined,
            color: AppColors.moduleNotes,
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
          const SizedBox(width: 6),
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
          const SizedBox(width: 6),
          FeatureHeaderButton(
            icon: Icons.add_rounded,
            label: 'New Note',
            color: AppColors.moduleNotes,
            onPressed: () => _openNoteEditor(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, NotesLoaded state) {
    final allNotes = state.notes;
    final totalPinned = allNotes.where((n) => n.isPinned).length;
    final totalChecklists = allNotes.where((n) => n.hasChecklist).length;

    final tagCounts = <String, int>{};
    for (final note in allNotes) {
      for (final tag in note.tags) {
        final clean = tag.trim();
        if (clean.isNotEmpty) {
          tagCounts[clean] = (tagCounts[clean] ?? 0) + 1;
        }
      }
    }

    final sortedTags = tagCounts.keys.toList()
      ..sort((a, b) => (tagCounts[b] ?? 0).compareTo(tagCounts[a] ?? 0));

    // Reset stale tag filter if last note with that tag was deleted
    final effectiveFilter =
        (_activeFilter != _filterAll &&
            _activeFilter != _filterPinned &&
            _activeFilter != _filterChecklists &&
            !tagCounts.containsKey(_activeFilter))
        ? _filterAll
        : _activeFilter;

    final query = _searchQuery.trim().toLowerCase();
    final filteredNotes = allNotes.where((note) {
      final matchesFilter = switch (effectiveFilter) {
        _filterAll => true,
        _filterPinned => note.isPinned,
        _filterChecklists => note.hasChecklist,
        _ => note.tags.contains(effectiveFilter),
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query) ||
          note.tags.any((t) => t.toLowerCase().contains(query));
    }).toList();

    switch (_sortOrder) {
      case _NoteSortOrder.titleAsc:
        filteredNotes.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case _NoteSortOrder.colorGroup:
        filteredNotes.sort((a, b) {
          final cmp = a.colorValue.compareTo(b.colorValue);
          if (cmp != 0) return cmp;
          return b.updatedAt.compareTo(a.updatedAt);
        });
      case _NoteSortOrder.updatedDesc:
        filteredNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    final pinnedNotes = filteredNotes.where((n) => n.isPinned).toList();
    final unpinnedNotes = filteredNotes.where((n) => !n.isPinned).toList();
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final isWide = viewportWidth >= 820;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.xs,
            AppSpacing.pageGutter,
            AppSpacing.huge * 2,
          ),
          children: [
            // ── 1. Calm 4-Stat Overview Strip ──────────────────────────────
            _buildOverviewStrip(
              context,
              totalCount: allNotes.length,
              pinnedCount: totalPinned,
              checklistCount: totalChecklists,
              tagsCount: tagCounts.length,
              effectiveFilter: effectiveFilter,
            ),
            const SizedBox(height: 12),

            // ── 2. Single-Surface Daily Scratchpad ─────────────────────────
            NotesScratchpadCard(
              controller: _scratchpadController,
              onChanged: _saveScratchpad,
              onSaveAsNote: () => _saveScratchpadAsNote(context),
              onClear: () => _clearScratchpad(context),
            ),
            const SizedBox(height: 14),

            // ── 3. Search + Sort + View Controls ───────────────────────────
            _buildSearchAndControlsBar(context),
            const SizedBox(height: 10),

            // ── 4. Smart Filter & @Tag Strip ───────────────────────────────
            if (allNotes.isNotEmpty) ...[
              _buildFilterStrip(
                context,
                totalCount: allNotes.length,
                pinnedCount: totalPinned,
                checklistCount: totalChecklists,
                sortedTags: sortedTags,
                tagCounts: tagCounts,
                effectiveFilter: effectiveFilter,
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 6),

            // ── 5. Notes Feed (Masonry Grid / Responsive List / Empty) ─────
            if (filteredNotes.isEmpty)
              _buildEmptyState(
                context,
                hasNotesInDb: allNotes.isNotEmpty,
                hasActiveFilter:
                    effectiveFilter != _filterAll || query.isNotEmpty,
              )
            else if (_isGridView) ...[
              if (pinnedNotes.isNotEmpty) ...[
                _buildEditorialSectionHeader(
                  context,
                  title: 'Pinned',
                  count: pinnedNotes.length,
                  accentColor: AppColors.moduleNotes,
                  icon: Icons.push_pin_rounded,
                ),
                const SizedBox(height: 10),
                _buildMasonryGrid(
                  context,
                  pinnedNotes,
                  viewportWidth: viewportWidth,
                ),
                if (unpinnedNotes.isNotEmpty) const SizedBox(height: 18),
              ],
              if (unpinnedNotes.isNotEmpty) ...[
                _buildEditorialSectionHeader(
                  context,
                  title: pinnedNotes.isNotEmpty ? 'Other Notes' : 'All Notes',
                  count: unpinnedNotes.length,
                ),
                const SizedBox(height: 10),
                _buildMasonryGrid(
                  context,
                  unpinnedNotes,
                  viewportWidth: viewportWidth,
                ),
              ],
            ] else if (isWide &&
                pinnedNotes.isNotEmpty &&
                unpinnedNotes.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildEditorialSectionHeader(
                          context,
                          title: 'Pinned',
                          count: pinnedNotes.length,
                          accentColor: AppColors.moduleNotes,
                          icon: Icons.push_pin_rounded,
                        ),
                        const SizedBox(height: 10),
                        _buildListColumn(context, pinnedNotes),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildEditorialSectionHeader(
                          context,
                          title: 'Other Notes',
                          count: unpinnedNotes.length,
                        ),
                        const SizedBox(height: 10),
                        _buildListColumn(context, unpinnedNotes),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              if (pinnedNotes.isNotEmpty) ...[
                _buildEditorialSectionHeader(
                  context,
                  title: 'Pinned',
                  count: pinnedNotes.length,
                  accentColor: AppColors.moduleNotes,
                  icon: Icons.push_pin_rounded,
                ),
                const SizedBox(height: 10),
                _buildListColumn(context, pinnedNotes),
                if (unpinnedNotes.isNotEmpty) const SizedBox(height: 18),
              ],
              if (unpinnedNotes.isNotEmpty) ...[
                _buildEditorialSectionHeader(
                  context,
                  title: pinnedNotes.isNotEmpty ? 'Other Notes' : 'All Notes',
                  count: unpinnedNotes.length,
                ),
                const SizedBox(height: 10),
                _buildListColumn(context, unpinnedNotes),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // ── 1. Calm 4-Stat Overview Strip ──────────────────────────────────────────
  Widget _buildOverviewStrip(
    BuildContext context, {
    required int totalCount,
    required int pinnedCount,
    required int checklistCount,
    required int tagsCount,
    required String effectiveFilter,
  }) {
    final palette = context.palette;

    Widget divider() => Container(
      width: 1,
      height: 26,
      color: palette.divider,
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: _OverviewMetricCell(
              value: '$totalCount',
              label: 'Total',
              accentColor: AppColors.moduleNotes,
              isActive: effectiveFilter == _filterAll,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _activeFilter = _filterAll);
              },
            ),
          ),
          divider(),
          Expanded(
            child: _OverviewMetricCell(
              value: '$pinnedCount',
              label: 'Pinned',
              accentColor: AppColors.moduleTime,
              isActive: effectiveFilter == _filterPinned,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _activeFilter = effectiveFilter == _filterPinned
                      ? _filterAll
                      : _filterPinned;
                });
              },
            ),
          ),
          divider(),
          Expanded(
            child: _OverviewMetricCell(
              value: '$checklistCount',
              label: 'Lists',
              accentColor: AppColors.moduleMoney,
              isActive: effectiveFilter == _filterChecklists,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _activeFilter = effectiveFilter == _filterChecklists
                      ? _filterAll
                      : _filterChecklists;
                });
              },
            ),
          ),
          divider(),
          Expanded(
            child: _OverviewMetricCell(
              value: '$tagsCount',
              label: '@Tags',
              accentColor: AppColors.moduleVault,
              isActive:
                  effectiveFilter != _filterAll &&
                  effectiveFilter != _filterPinned &&
                  effectiveFilter != _filterChecklists,
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Search + Sort + View Controls ───────────────────────────────────────
  Widget _buildSearchAndControlsBar(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final isNonDefaultSort = _sortOrder != _NoteSortOrder.updatedDesc;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: AppRadius.radiusSm,
              border: Border.all(color: palette.divider),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 17, color: palette.caption),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: palette.heading,
                    ),
                    decoration: InputDecoration(
                      filled: false,
                      isDense: true,
                      hintText: 'Search notes, checklists, or @tags...',
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: palette.caption,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: palette.caption,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Sort: $_sortLabel',
          child: InkWell(
            key: const ValueKey('toggle_notes_sort'),
            borderRadius: AppRadius.radiusSm,
            onTap: _cycleSortOrder,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isNonDefaultSort
                    ? AppColors.moduleNotes.withValues(
                        alpha: palette.isDark ? 0.20 : 0.12,
                      )
                    : palette.card,
                borderRadius: AppRadius.radiusSm,
                border: Border.all(
                  color: isNonDefaultSort
                      ? AppColors.moduleNotes.withValues(alpha: 0.50)
                      : palette.divider,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    switch (_sortOrder) {
                      _NoteSortOrder.updatedDesc => Icons.swap_vert_rounded,
                      _NoteSortOrder.titleAsc => Icons.sort_by_alpha_rounded,
                      _NoteSortOrder.colorGroup => Icons.palette_outlined,
                    },
                    size: 18,
                    color: isNonDefaultSort
                        ? AppColors.moduleNotes
                        : palette.icon,
                  ),
                  if (isNonDefaultSort)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.moduleNotes,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: _isGridView ? 'Switch to List view' : 'Switch to Grid view',
          child: InkWell(
            key: const ValueKey('toggle_notes_view_mode'),
            borderRadius: AppRadius.radiusSm,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isGridView = !_isGridView);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _isGridView
                    ? AppColors.moduleNotes.withValues(
                        alpha: palette.isDark ? 0.20 : 0.12,
                      )
                    : palette.card,
                borderRadius: AppRadius.radiusSm,
                border: Border.all(
                  color: _isGridView
                      ? AppColors.moduleNotes.withValues(alpha: 0.50)
                      : palette.divider,
                ),
              ),
              child: Icon(
                _isGridView
                    ? Icons.view_agenda_outlined
                    : Icons.grid_view_rounded,
                size: 17.5,
                color: _isGridView ? AppColors.moduleNotes : palette.icon,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 4. Smart Filter & @Tag Strip ───────────────────────────────────────────
  Widget _buildFilterStrip(
    BuildContext context, {
    required int totalCount,
    required int pinnedCount,
    required int checklistCount,
    required List<String> sortedTags,
    required Map<String, int> tagCounts,
    required String effectiveFilter,
  }) {
    final items = <_FilterChipData>[
      _FilterChipData(
        keyValue: _filterAll,
        label: 'All',
        count: totalCount,
        icon: Icons.notes_rounded,
      ),
      if (pinnedCount > 0 || effectiveFilter == _filterPinned)
        _FilterChipData(
          keyValue: _filterPinned,
          label: 'Pinned',
          count: pinnedCount,
          icon: Icons.push_pin_rounded,
        ),
      if (checklistCount > 0 || effectiveFilter == _filterChecklists)
        _FilterChipData(
          keyValue: _filterChecklists,
          label: 'Checklists',
          count: checklistCount,
          icon: Icons.checklist_rounded,
        ),
      for (final tag in sortedTags)
        _FilterChipData(keyValue: tag, label: tag, count: tagCounts[tag] ?? 0),
    ];

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = effectiveFilter == item.keyValue;
          return _buildFilterChip(context, item: item, selected: selected);
        },
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required _FilterChipData item,
    required bool selected,
  }) {
    final palette = context.palette;
    final textTheme = context.text;

    return InkWell(
      key: ValueKey('notes_filter_${item.keyValue}'),
      borderRadius: AppRadius.radiusFull,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _activeFilter = selected && item.keyValue != _filterAll
              ? _filterAll
              : item.keyValue;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.moduleNotes : palette.card,
          borderRadius: AppRadius.radiusFull,
          border: Border.all(
            color: selected ? AppColors.moduleNotes : palette.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.icon != null) ...[
              Icon(
                item.icon,
                size: 13,
                color: selected ? AppColors.textWhite : palette.secondary,
              ),
              const SizedBox(width: 5),
            ],
            AppText(
              item.label,
              style: textTheme.labelSmall?.copyWith(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? AppColors.textWhite : palette.body,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.textWhite.withValues(alpha: 0.22)
                    : palette.surfaceMuted,
                borderRadius: AppRadius.radiusFull,
              ),
              child: AppText(
                '${item.count}',
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.textWhite : palette.caption,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 5a. Editorial Section Header ───────────────────────────────────────────
  Widget _buildEditorialSectionHeader(
    BuildContext context, {
    required String title,
    required int count,
    Color? accentColor,
    IconData? icon,
  }) {
    final palette = context.palette;
    final textTheme = context.text;
    final badgeTint = accentColor ?? palette.secondary;

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: accentColor ?? palette.secondary),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: AppText(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: palette.heading,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: accentColor != null
                ? badgeTint.withValues(alpha: palette.isDark ? 0.20 : 0.12)
                : palette.surfaceMuted,
            borderRadius: AppRadius.radiusFull,
          ),
          child: AppText(
            '$count',
            style: textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accentColor ?? palette.caption,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  // ── 5b. Single-Column List Feed ────────────────────────────────────────────
  Widget _buildListColumn(BuildContext context, List<NoteEntity> notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < notes.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == notes.length - 1 ? 0 : 12),
            child: StaggeredFadeSlide(
              index: i,
              child: _buildWiredNoteCard(
                context,
                notes[i],
                isCompactGrid: false,
              ),
            ),
          ),
      ],
    );
  }

  // ── 5c. True Balanced Masonry Grid ─────────────────────────────────────────
  Widget _buildMasonryGrid(
    BuildContext context,
    List<NoteEntity> notes, {
    required double viewportWidth,
  }) {
    final columnCount = viewportWidth >= 960 ? 3 : 2;
    final columns = List<List<NoteEntity>>.generate(columnCount, (_) => []);
    final heights = List<double>.filled(columnCount, 0.0);

    for (final note in notes) {
      var shortestIdx = 0;
      for (var c = 1; c < columnCount; c++) {
        if (heights[c] < heights[shortestIdx]) {
          shortestIdx = c;
        }
      }
      columns[shortestIdx].add(note);
      heights[shortestIdx] += _estimateCardWeight(note);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var col = 0; col < columnCount; col++) ...[
          if (col > 0) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var row = 0; row < columns[col].length; row++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: row == columns[col].length - 1 ? 0 : 12,
                    ),
                    child: StaggeredFadeSlide(
                      index: col + (row * columnCount),
                      child: _buildWiredNoteCard(
                        context,
                        columns[col][row],
                        isCompactGrid: true,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  double _estimateCardWeight(NoteEntity note) {
    final titleLines = (note.title.length / 22).ceil().clamp(1, 2);
    final checklistCount = note.checklistTotalCount.clamp(0, 4);
    final proseChars = note.content
        .split('\n')
        .where((l) => !NoteEntity.isChecklistLine(l))
        .join(' ')
        .length;
    final proseLines = proseChars == 0
        ? 0
        : (proseChars / 28).ceil().clamp(1, 4);
    final tagRow = note.tags.any((t) => t.trim().isNotEmpty) ? 24.0 : 0.0;
    return 84.0 +
        (titleLines * 18.0) +
        (proseLines * 17.0) +
        (checklistCount > 0 ? 34.0 + (checklistCount * 22.0) : 0.0) +
        tagRow;
  }

  Widget _buildWiredNoteCard(
    BuildContext context,
    NoteEntity note, {
    required bool isCompactGrid,
  }) {
    return NoteCardWidget(
      key: ValueKey('note_card_${note.id}'),
      note: note,
      isCompactGrid: isCompactGrid,
      onTap: () => _openNoteEditor(context, note: note),
      onTogglePin: () => context.read<NotesBloc>().add(TogglePinNote(note.id)),
      onDuplicate: () => _duplicateNote(context, note),
      onCopy: () => _copyToClipboard(context, note),
      onConvertToTask: () => _convertToPlannerTask(context, note),
      onPushToTimeline: () => _pushToTodayTimeline(context, note),
      onConvertToExpense: () => _convertToExpense(context, note),
      onDelete: () => _deleteNoteWithConfirmation(context, note),
      onToggleChecklistLine: (lineIdx) =>
          _toggleChecklistLine(context, note, lineIdx),
      onSelectTag: (tag) {
        setState(() {
          _activeFilter = _activeFilter == tag ? _filterAll : tag;
        });
      },
    );
  }

  // ── 5d. Clean Editorial Empty State ────────────────────────────────────────
  Widget _buildEmptyState(
    BuildContext context, {
    required bool hasNotesInDb,
    required bool hasActiveFilter,
  }) {
    final palette = context.palette;
    final textTheme = context.text;

    final title = hasNotesInDb && hasActiveFilter
        ? 'No matching notes'
        : 'Your notebook is ready';
    final subtitle = hasNotesInDb && hasActiveFilter
        ? 'Try another search keyword or clear the active filter.'
        : 'Capture ideas, interactive checklists, voice memos, or quick receipts.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.moduleNotes.withValues(
                alpha: palette.isDark ? 0.18 : 0.12,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              hasActiveFilter
                  ? Icons.search_off_rounded
                  : Icons.sticky_note_2_outlined,
              size: 24,
              color: AppColors.moduleNotes,
            ),
          ),
          const SizedBox(height: 14),
          AppText(
            title,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: palette.heading,
            ),
          ),
          const SizedBox(height: 6),
          AppText(
            subtitle,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 13,
              height: 1.45,
              color: palette.secondary,
            ),
          ),
          const SizedBox(height: 16),
          if (hasNotesInDb && hasActiveFilter)
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _activeFilter = _filterAll;
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.moduleNotes,
                side: BorderSide(color: palette.divider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: const AppText('Clear Filters'),
            )
          else
            FilledButton.icon(
              onPressed: () => _openNoteEditor(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.moduleNotes,
                foregroundColor: AppColors.textWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 17),
              label: const AppText('Create First Note'),
            ),
        ],
      ),
    );
  }
}

class _OverviewMetricCell extends StatelessWidget {
  final String value;
  final String label;
  final Color accentColor;
  final bool isActive;
  final VoidCallback? onTap;

  const _OverviewMetricCell({
    required this.value,
    required this.label,
    required this.accentColor,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isActive && onTap != null
            ? accentColor.withValues(alpha: palette.isDark ? 0.16 : 0.10)
            : AppColors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AppText(
              value,
              maxLines: 1,
              style: textTheme.titleMedium?.copyWith(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: isActive ? accentColor : palette.heading,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AppText(
              label,
              maxLines: 1,
              style: textTheme.labelSmall?.copyWith(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? accentColor : palette.caption,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: content,
    );
  }
}

class _FilterChipData {
  final String keyValue;
  final String label;
  final int count;
  final IconData? icon;

  const _FilterChipData({
    required this.keyValue,
    required this.label,
    required this.count,
    this.icon,
  });
}
