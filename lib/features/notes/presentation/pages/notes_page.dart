import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/widgets/app_dropdown_menu.dart';
import '../../../../core/widgets/app_shimmer_loader.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/quick_capture_sheet.dart';
import '../../../../di/injection_container.dart';
import '../../domain/entities/note_entity.dart';
import '../bloc/notes_bloc.dart';

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

  // Palette of curated modern accent colors for notes
  static const List<int> _notePalette = [
    0xFFF59E0B, // Amber Gold
    0xFF10B981, // Emerald Green
    0xFF3B82F6, // Ocean Blue
    0xFF8B5CF6, // Violet Purple
    0xFFF43F5E, // Rose Pink
    0xFF64748B, // Slate Grey
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : AppColors.scaffoldBackground,
      appBar: AppBar(
        toolbarHeight: 48,
        titleSpacing: 16,
        title: const Text(
          StringConstants.navNotes,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Camera OCR Scan',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.document_scanner_rounded,
              size: 18,
              color: isDark ? AppColors.darkTextBody : AppColors.textBody,
            ),
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
          IconButton(
            tooltip: 'Voice Note',
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.mic_rounded,
              size: 18,
              color: AppColors.voiceWaveform,
            ),
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
          Padding(
            padding: const EdgeInsets.only(right: 14, left: 4),
            child: Center(
              child: InkWell(
                onTap: () => _showNoteEditor(context),
                borderRadius: AppRadius.radiusSm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.moduleNotes,
                    borderRadius: AppRadius.radiusSm,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 15, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'New Note',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<NotesBloc, NotesState>(
        builder: (context, state) {
          if (state is NotesLoading || state is NotesInitial) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: const [
                AppShimmerLoader.card(height: 68),
                SizedBox(height: 10),
                AppShimmerLoader.card(height: 38),
                SizedBox(height: 12),
                AppShimmerLoader.card(height: 88),
                SizedBox(height: 8),
                AppShimmerLoader.card(height: 88),
              ],
            );
          }
          if (state is NotesError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 36,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Error: ${state.message}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () =>
                          context.read<NotesBloc>().add(const LoadNotes()),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is NotesLoaded) {
            return _buildContent(context, state, isDark);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, NotesLoaded state, bool isDark) {
    final allTags = {
      'All',
      ...state.notes.expand((n) => n.tags),
    }.where((t) => t.isNotEmpty).toList();

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

    final pinnedNotes = filteredNotes.where((n) => n.isPinned).toList();
    final unpinnedNotes = filteredNotes.where((n) => !n.isPinned).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 84),
      children: [
        // ── 1. Compact Search & Filter Bar ───────────────────────────────
        _buildSearchBar(isDark),
        const SizedBox(height: 8),

        // ── 2. Compact Daily Scratchpad ──────────────────────────────────
        _buildScratchpadCard(context, isDark),
        const SizedBox(height: 10),

        // ── 3. Tag Filter Strip ──────────────────────────────────────────
        if (allTags.length > 1) ...[
          SizedBox(
            height: 28,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: allTags.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) =>
                  _buildTagChip(context, allTags[index], isDark),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── 4. Empty State or Compact Note List ──────────────────────────
        if (filteredNotes.isEmpty)
          _buildEmptyNotesState(isDark)
        else ...[
          if (pinnedNotes.isNotEmpty) ...[
            _buildSectionHeader(
              icon: Icons.push_pin_rounded,
              iconColor: AppColors.moduleNotes,
              label: 'PINNED (${pinnedNotes.length})',
            ),
            const SizedBox(height: 6),
            ...pinnedNotes.map((note) => _buildNoteCard(context, note, isDark)),
            const SizedBox(height: 8),
          ],
          if (unpinnedNotes.isNotEmpty) ...[
            if (pinnedNotes.isNotEmpty) ...[
              _buildSectionHeader(
                icon: Icons.notes_rounded,
                iconColor: AppColors.textCaption,
                label: 'ALL NOTES (${unpinnedNotes.length})',
              ),
              const SizedBox(height: 6),
            ],
            ...unpinnedNotes.map(
              (note) => _buildNoteCard(context, note, isDark),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 12, color: iconColor),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ── Compact Daily Scratchpad Widget ────────────────────────────────────────
  Widget _buildScratchpadCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: isDark
              ? AppColors.darkDivider
              : AppColors.moduleNotes.withValues(alpha: 0.22),
          width: 0.8,
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
                  const Icon(
                    Icons.bolt_rounded,
                    color: AppColors.moduleNotes,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    StringConstants.dailyScratchpad.toUpperCase(),
                    style: AppTextStyles.overline.copyWith(
                      color: AppColors.moduleNotes,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _scratchpadController,
                builder: (context, value, _) {
                  final hasText = value.text.trim().isNotEmpty;
                  if (!hasText) return const SizedBox.shrink();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _saveScratchpadAsNote(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.moduleNotes.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: AppRadius.radiusXs,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.save_rounded,
                                size: 11,
                                color: AppColors.moduleNotes,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                StringConstants.save,
                                style: AppTextStyles.captionBold.copyWith(
                                  fontSize: 10,
                                  color: AppColors.moduleNotes,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _clearScratchpad(context),
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: isDark
                              ? AppColors.darkTextCaption
                              : AppColors.textCaption,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _scratchpadController,
            onChanged: _saveScratchpad,
            minLines: 1,
            maxLines: 3,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
              height: 1.3,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: StringConstants.scratchpadHint,
              hintStyle: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextCaption
                    : AppColors.textCaption,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  // ── Compact Search Bar Widget ──────────────────────────────────────────────
  Widget _buildSearchBar(bool isDark) {
    return SizedBox(
      height: 36,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: AppRadius.radiusSm,
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.border,
            width: 0.8,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search notes, tags, or content...',
            hintStyle: TextStyle(
              color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
              fontSize: 12,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isDark ? AppColors.darkTextCaption : AppColors.iconColor,
              size: 16,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 34,
              minHeight: 34,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: isDark
                          ? AppColors.darkTextCaption
                          : AppColors.textCaption,
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }

  // ── Compact Tag Filter Chip ────────────────────────────────────────────────
  Widget _buildTagChip(BuildContext context, String tag, bool isDark) {
    final isSelected = _selectedTag == tag;
    return GestureDetector(
      onTap: () => setState(() => _selectedTag = tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.moduleNotes
              : (isDark
                    ? AppColors.darkCardBackground
                    : AppColors.cardBackground),
          borderRadius: AppRadius.radiusFull,
          border: Border.all(
            color: isSelected
                ? AppColors.moduleNotes
                : (isDark ? AppColors.darkDivider : AppColors.divider),
            width: 0.8,
          ),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextBody : AppColors.textBody),
          ),
        ),
      ),
    );
  }

  // ── Empty Notes State ──────────────────────────────────────────────────────
  Widget _buildEmptyNotesState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            _searchQuery.isNotEmpty
                ? Icons.search_off_rounded
                : Icons.note_alt_outlined,
            size: 36,
            color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'No notes match "$_searchQuery"'
                : 'No notes in this view',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          const SizedBox(height: 4),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different keyword or clear the filter.'
                : 'Tap "New Note" above or jot in the scratchpad.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 11.5),
              ),
              child: const Text('Clear Filter'),
            ),
          ],
        ],
      ),
    );
  }

  // ── Compact Note Card ──────────────────────────────────────────────────────
  Widget _buildNoteCard(BuildContext context, NoteEntity note, bool isDark) {
    final noteColor = note.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: note.isPinned
              ? noteColor.withValues(alpha: 0.45)
              : (isDark ? AppColors.darkDivider : AppColors.divider),
          width: note.isPinned ? 1.1 : 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.radiusMd,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Subtle Left Accent Strip
              Container(width: 3.5, color: noteColor),

              // Main Compact Body
              Expanded(
                child: InkWell(
                  onTap: () => _showNoteEditor(context, note: note),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row: Title + Pin + More Menu
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                note.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: isDark
                                      ? AppColors.darkTextHeading
                                      : AppColors.textHeading,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Tooltip(
                              message: note.isPinned ? 'Unpin' : 'Pin note',
                              child: InkWell(
                                borderRadius: AppRadius.radiusXs,
                                onTap: () => context.read<NotesBloc>().add(
                                  TogglePinNote(note.id),
                                ),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Icon(
                                    note.isPinned
                                        ? Icons.push_pin_rounded
                                        : Icons.push_pin_outlined,
                                    size: 15,
                                    color: note.isPinned
                                        ? noteColor
                                        : (isDark
                                              ? AppColors.darkTextCaption
                                              : AppColors.textCaption),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            _buildCardDropdownMenu(context, note, isDark),
                          ],
                        ),

                        if (note.previewContent.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            note.previewContent,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextBody
                                  : AppColors.textBody,
                              height: 1.35,
                            ),
                          ),
                        ],

                        const SizedBox(height: 7),

                        // Compact Footer: Tags + Convert to Task Pill
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: note.tags.isNotEmpty
                                  ? Wrap(
                                      spacing: 4,
                                      runSpacing: 3,
                                      children: note.tags
                                          .take(3)
                                          .map(
                                            (tag) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 1.5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: noteColor.withValues(
                                                  alpha: 0.11,
                                                ),
                                                borderRadius:
                                                    AppRadius.radiusXs,
                                              ),
                                              child: Text(
                                                tag,
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: noteColor,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    )
                                  : Text(
                                      _formatShortDate(note.updatedAt),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark
                                            ? AppColors.darkTextCaption
                                            : AppColors.textCaption,
                                      ),
                                    ),
                            ),
                            _buildConverterButton(
                              context: context,
                              label: '-> Task',
                              icon: Icons.add_task_rounded,
                              color: AppColors.moduleTime,
                              onTap: () => _convertToPlannerTask(context, note),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
  Widget _buildCardDropdownMenu(
    BuildContext context,
    NoteEntity note,
    bool isDark,
  ) {
    return AppDropdownMenu<String>(
      tooltip: 'Note actions',
      icon: Icon(
        Icons.more_horiz_rounded,
        size: 16,
        color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
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
          tintColor: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
        ),
        AppDropdownItem<String>(
          value: 'pin',
          icon: note.isPinned
              ? Icons.push_pin_outlined
              : Icons.push_pin_rounded,
          label: note.isPinned ? 'Unpin' : 'Pin to Top',
          tintColor: note.isPinned
              ? AppColors.moduleNotes
              : (isDark ? AppColors.darkTextHeading : AppColors.textHeading),
        ),
        AppDropdownItem<String>(
          value: 'copy',
          icon: Icons.copy_rounded,
          label: 'Copy Text',
          tintColor: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
        ),
        AppDropdownItem<String>(
          value: 'convert_task',
          icon: Icons.add_task_rounded,
          label: 'Add to Planner',
          tintColor: AppColors.moduleTime,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadius.radiusXs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Converted "$taskTitle" to Planner Reminder!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not convert to task: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
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

  // ── Compact Note Editor Modal Sheet (Create & Edit) ────────────────────────
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
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;

        return BlocProvider.value(
          value: notesBloc,
          child: StatefulBuilder(
            builder: (sheetStateContext, setSheetState) {
              return Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBackground : Colors.white,
                  borderRadius: AppRadius.topXl,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 32,
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkDivider
                                : AppColors.divider,
                            borderRadius: AppRadius.radiusFull,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing ? 'Edit Note' : 'Create New Note',
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Row(
                            children: [
                              if (isEditing)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 19,
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
                                icon: const Icon(Icons.close_rounded, size: 19),
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title Input
                      TextField(
                        controller: titleCtrl,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Note Title...',
                          hintStyle: TextStyle(
                            fontSize: 14.5,
                            color: isDark
                                ? AppColors.darkTextCaption
                                : AppColors.textCaption,
                            fontWeight: FontWeight.w600,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(selectedColor),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(selectedColor),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Color Palette Selector
                      Row(
                        children: [
                          Text(
                            'Color Accent: ',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextCaption
                                  : AppColors.textCaption,
                            ),
                          ),
                          const SizedBox(width: 6),
                          ..._notePalette.map((colorVal) {
                            final isSelected = selectedColor == colorVal;
                            return GestureDetector(
                              onTap: () {
                                setSheetState(() => selectedColor = colorVal);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 7),
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Color(colorVal),
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.white,
                                          width: 1.8,
                                        )
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 12,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Formatting Shortcut Tools
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildEditorHelperChip(
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
                                contentCtrl.text = newText;
                              },
                            ),
                            const SizedBox(width: 6),
                            _buildEditorHelperChip(
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
                                contentCtrl.text = newText;
                              },
                            ),
                            const SizedBox(width: 6),
                            _buildEditorHelperChip(
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
                                contentCtrl.text = newText;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Content Input Field
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceSecondary
                              : AppColors.surfaceSecondary,
                          borderRadius: AppRadius.radiusMd,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                            width: 0.8,
                          ),
                        ),
                        child: TextField(
                          controller: contentCtrl,
                          maxLines: 5,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: isDark
                                ? AppColors.darkTextHeading
                                : AppColors.textHeading,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText:
                                'Write your thoughts, checklists, or plans...',
                            hintStyle: TextStyle(fontSize: 12.5),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Quick Tag Chips
                      Text(
                        'Tags:',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextCaption
                              : AppColors.textCaption,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          ..._suggestedTags.map((tag) {
                            final isTagActive = activeTags.contains(tag);
                            return FilterChip(
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              selected: isTagActive,
                              label: Text(
                                tag,
                                style: const TextStyle(fontSize: 10.5),
                              ),
                              selectedColor: Color(
                                selectedColor,
                              ).withValues(alpha: 0.2),
                              checkmarkColor: Color(selectedColor),
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
                          }),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Custom Tag Input Row
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 34,
                              child: TextField(
                                controller: customTagCtrl,
                                style: const TextStyle(fontSize: 12),
                                decoration: const InputDecoration(
                                  hintText: 'Add custom tag (e.g. @Meeting)',
                                  hintStyle: TextStyle(fontSize: 11.5),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 34,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                textStyle: const TextStyle(fontSize: 11.5),
                              ),
                              child: const Text('Add Tag'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Save / Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 42,
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
                            backgroundColor: Color(selectedColor),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.radiusSm,
                            ),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 17),
                          label: Text(
                            isEditing ? 'Save Changes' : 'Create Note',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
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
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      avatar: Icon(icon, size: 13),
      label: Text(label, style: const TextStyle(fontSize: 10.5)),
      onPressed: onTap,
    );
  }
}
