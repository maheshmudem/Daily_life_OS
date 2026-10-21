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
        // Clear any old hardcoded locksmith text that was auto-saved to preferences
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
      message: 'Are you sure you want to erase the scratchpad? This cannot be undone.',
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
      backgroundColor:
          isDark ? AppColors.darkScaffoldBackground : AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          StringConstants.navNotes,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'New Note',
            icon: const Icon(Icons.note_add_rounded, color: AppColors.moduleNotes),
            onPressed: () => _showNoteEditor(context),
          ),
          IconButton(
            tooltip: 'Camera OCR Scan',
            icon: const Icon(Icons.document_scanner_rounded, color: AppColors.moduleNotes),
            onPressed: () => QuickCaptureSheet.show(context, mode: QuickCaptureMode.scan),
          ),
          IconButton(
            tooltip: 'Voice Note',
            icon: const Icon(Icons.mic_rounded, color: AppColors.voiceWaveform),
            onPressed: () => QuickCaptureSheet.show(context, mode: QuickCaptureMode.voice),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 85),
        child: FloatingActionButton.extended(
          onPressed: () => _showNoteEditor(context),
          backgroundColor: AppColors.moduleNotes,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Note', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
      body: BlocBuilder<NotesBloc, NotesState>(
        builder: (context, state) {
          if (state is NotesLoading || state is NotesInitial) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                AppShimmerLoader.card(height: 120),
                SizedBox(height: 16),
                AppShimmerLoader.card(height: 50),
                SizedBox(height: 16),
                AppShimmerLoader.card(height: 140),
                SizedBox(height: 12),
                AppShimmerLoader.card(height: 140),
              ],
            );
          }
          if (state is NotesError) {
            return Center(child: Text('Error: ${state.message}'));
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

    // Filter notes by search query and selected tag
    final query = _searchQuery.trim().toLowerCase();
    final filteredNotes = state.notes.where((note) {
      final matchesTag =
          _selectedTag == 'All' || note.tags.contains(_selectedTag);
      final matchesSearch = query.isEmpty ||
          note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query) ||
          note.tags.any((t) => t.toLowerCase().contains(query));
      return matchesTag && matchesSearch;
    }).toList();

    final pinnedNotes = filteredNotes.where((n) => n.isPinned).toList();
    final unpinnedNotes = filteredNotes.where((n) => !n.isPinned).toList();

    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
      children: [
        // ── 1. Daily Scratchpad (Auto-saving & Actionable) ───────────────
        _buildScratchpadCard(context, isDark),
        const SizedBox(height: 16),

        // ── 2. Live Search Bar ──────────────────────────────────────────
        _buildSearchBar(isDark),
        const SizedBox(height: 14),

        // ── 3. Tag Filter Strip ─────────────────────────────────────────
        if (allTags.length > 1) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: allTags
                  .map((tag) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildTagChip(context, tag, isDark),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── 4. Empty State or Results ───────────────────────────────────
        if (filteredNotes.isEmpty)
          _buildEmptyNotesState(isDark)
        else ...[
          // Pinned Notes Section
          if (pinnedNotes.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.push_pin_rounded,
                    size: 14, color: AppColors.moduleNotes),
                AppSpacing.gapW8,
                Text(
                  'PINNED NOTES (${pinnedNotes.length})',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...pinnedNotes.map((note) => _buildNoteCard(context, note, isDark)),
            const SizedBox(height: 12),
          ],

          // Other / Unpinned Notes Section
          if (unpinnedNotes.isNotEmpty) ...[
            if (pinnedNotes.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.notes_rounded,
                      size: 14, color: AppColors.textCaption),
                  AppSpacing.gapW8,
                  Text(
                    'OTHER NOTES (${unpinnedNotes.length})',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            ...unpinnedNotes.map((note) => _buildNoteCard(context, note, isDark)),
          ],
        ],
      ],
    );
  }

  // ── Daily Scratchpad Widget ──────────────────────────────────────────────
  Widget _buildScratchpadCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: isDark
              ? AppColors.darkDivider
              : AppColors.moduleNotes.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_note_rounded,
                      color: AppColors.moduleNotes, size: 16),
                  AppSpacing.gapW8,
                  Text(
                    StringConstants.dailyScratchpad.toUpperCase(),
                    style: AppTextStyles.overline.copyWith(
                      color: AppColors.moduleNotes,
                      fontSize: 10.5,
                      letterSpacing: 0.6,
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
                              horizontal: AppSpacing.xs, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.moduleNotes.withValues(alpha: 0.12),
                            borderRadius: AppRadius.radiusXs,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.save_rounded,
                                  size: 12, color: AppColors.moduleNotes),
                              AppSpacing.gapW4,
                              Text(
                                StringConstants.save,
                                style: AppTextStyles.captionBold.copyWith(
                                  fontSize: 10.5,
                                  color: AppColors.moduleNotes,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AppSpacing.gapW8,
                      GestureDetector(
                        onTap: () => _clearScratchpad(context),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.06),
                            borderRadius: AppRadius.radiusXs,
                          ),
                          child: Icon(Icons.close_rounded,
                              size: 13,
                              color: isDark
                                  ? AppColors.darkTextCaption
                                  : AppColors.textCaption),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          AppSpacing.gapH8,
          TextField(
            controller: _scratchpadController,
            onChanged: _saveScratchpad,
            minLines: 1,
            maxLines: 4,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
              height: 1.35,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: StringConstants.scratchpadHint,
              hintStyle: AppTextStyles.bodySmall.copyWith(
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

  // ── Search Bar Widget ────────────────────────────────────────────────────
  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.border,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: TextStyle(
          fontSize: 14,
          color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
        ),
        decoration: InputDecoration(
          hintText: 'Search notes, tags, or content...',
          hintStyle: TextStyle(
            color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? AppColors.darkTextCaption : AppColors.iconColor,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // ── Tag Filter Chip ──────────────────────────────────────────────────────
  Widget _buildTagChip(BuildContext context, String tag, bool isDark) {
    final isSelected = _selectedTag == tag;
    return GestureDetector(
      onTap: () => setState(() => _selectedTag = tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.moduleNotes
              : (isDark ? AppColors.darkCardBackground : AppColors.cardBackground),
          borderRadius: AppRadius.radiusFull,
          border: Border.all(
            color: isSelected
                ? AppColors.moduleNotes
                : (isDark ? AppColors.darkDivider : AppColors.divider),
          ),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextBody : AppColors.textBody),
          ),
        ),
      ),
    );
  }

  // ── Empty Notes State ────────────────────────────────────────────────────
  Widget _buildEmptyNotesState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.note_alt_outlined,
            size: 48,
            color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'No notes match "$_searchQuery"'
                : 'No notes found in this category',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try searching with a different term or clear the filter.'
                : 'Tap "New Note" or use Voice to jot down your first idea.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Text('Clear Search Filter'),
            ),
          ],
        ],
      ),
    );
  }

  // ── Note Card (Tappable, Editable, Deletable, Actionable) ─────────────────
  Widget _buildNoteCard(BuildContext context, NoteEntity note, bool isDark) {
    final noteColor = note.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: note.isPinned
              ? noteColor.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkDivider : AppColors.divider),
          width: note.isPinned ? 1.5 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.radiusLg,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colored Accent Strip on Left
              Container(
                width: 5,
                color: noteColor,
              ),

              // Main Note Body
              Expanded(
                child: InkWell(
                  onTap: () => _showNoteEditor(context, note: note),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header: Title, Pin Indicator & 3-Dots Menu
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (note.isPinned) ...[
                              Icon(Icons.push_pin_rounded,
                                  size: 15, color: noteColor),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                note.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: isDark
                                      ? AppColors.darkTextHeading
                                      : AppColors.textHeading,
                                ),
                              ),
                            ),
                            // Quick Pin Toggle
                            IconButton(
                              icon: Icon(
                                note.isPinned
                                    ? Icons.push_pin_rounded
                                    : Icons.push_pin_outlined,
                                size: 18,
                                color: note.isPinned
                                    ? AppColors.moduleNotes
                                    : (isDark
                                        ? AppColors.darkTextCaption
                                        : AppColors.textCaption),
                              ),
                              tooltip: note.isPinned ? 'Unpin' : 'Pin note',
                              onPressed: () => context
                                  .read<NotesBloc>()
                                  .add(TogglePinNote(note.id)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 4),
                            // Professional Dropdown Popup Menu
                            _buildCardDropdownMenu(context, note, isDark),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Preview Content
                        Text(
                          note.previewContent,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextBody
                                : AppColors.textBody,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Card Footer: Tags, Date & Cross-Module Quick Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Tags
                            Expanded(
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: note.tags
                                    .take(3)
                                    .map((tag) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: noteColor.withValues(alpha: 0.12),
                                            borderRadius: AppRadius.radiusSm,
                                          ),
                                          child: Text(
                                            tag,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: noteColor,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),

                            // Cross-Module Converters & Edit Trigger
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildConverterButton(
                                  context: context,
                                  label: '-> Task',
                                  icon: Icons.add_task_rounded,
                                  color: AppColors.moduleTime,
                                  onTap: () => _convertToPlannerTask(context, note),
                                ),
                                const SizedBox(width: 6),
                                _buildConverterButton(
                                  context: context,
                                  label: 'Edit',
                                  icon: Icons.edit_rounded,
                                  color: AppColors.moduleNotes,
                                  onTap: () => _showNoteEditor(context, note: note),
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
            ],
          ),
        ),
      ),
    );
  }

  // ── Card Dropdown Popup Menu ───────────────────────────────────────────────
  Widget _buildCardDropdownMenu(
      BuildContext context, NoteEntity note, bool isDark) {
    return AppDropdownMenu<String>(
      tooltip: 'Note actions',
      icon: Icon(
        Icons.more_horiz_rounded,
        size: 18,
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

  // ── Converter Button Pill ────────────────────────────────────────────────
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadius.radiusSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions: Copy to Clipboard ───────────────────────────────────────────
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

  // ── Actions: Convert Note to Task in Planner (Actual SQLite Insert) ───────
  Future<void> _convertToPlannerTask(
      BuildContext context, NoteEntity note) async {
    try {
      final db = sl<AppDatabase>();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final taskTitle =
          note.title.isNotEmpty ? note.title : 'Reminder from note';

      await db.into(db.plannerItems).insert(
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
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {},
            ),
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

  // ── Actions: Delete Note with Confirmation ────────────────────────────────
  Future<void> _deleteNoteWithConfirmation(
      BuildContext context, NoteEntity note) async {
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

  // ── Full Note Editor Modal Sheet (Create & Edit) ──────────────────────────
  void _showNoteEditor(BuildContext context, {NoteEntity? note}) {
    final notesBloc = context.read<NotesBloc>();
    final isEditing = note != null;
    final titleCtrl = TextEditingController(text: note?.title ?? '');
    final contentCtrl = TextEditingController(text: note?.content ?? '');
    final customTagCtrl = TextEditingController();

    int selectedColor = note?.colorValue ?? _notePalette.first;
    final List<String> activeTags =
        note != null ? List<String>.from(note.tags) : [];

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
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardBackground
                    : Colors.white,
                borderRadius: AppRadius.topXxl,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 25,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    // Sheet Drag Handle
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkDivider
                              : AppColors.divider,
                          borderRadius: AppRadius.radiusFull,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Sheet Header with Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Note' : 'Create New Note',
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Row(
                          children: [
                            // Delete button if editing
                            if (isEditing)
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: AppColors.error),
                                tooltip: 'Delete Note',
                                onPressed: () async {
                                  final confirmed =
                                      await ConfirmationDialog.show(
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Note deleted.'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.of(sheetContext).pop(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title Input
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Note Title...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.darkTextCaption
                              : AppColors.textCaption,
                          fontWeight: FontWeight.w600,
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(selectedColor),
                            width: 2,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(selectedColor),
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Color Palette Selector
                    Row(
                      children: [
                        Text(
                          'Color Accent: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextCaption
                                : AppColors.textCaption,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ..._notePalette.map((colorVal) {
                          final isSelected = selectedColor == colorVal;
                          return GestureDetector(
                            onTap: () {
                              setSheetState(() => selectedColor = colorVal);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Color(colorVal),
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Color(colorVal)
                                              .withValues(alpha: 0.6),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      size: 14, color: Colors.white)
                                  : null,
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 14),

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
                                      selection.start >= 0 ? selection.start : text.length,
                                      selection.end >= 0 ? selection.end : text.length,
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
                                      selection.start >= 0 ? selection.start : text.length,
                                      selection.end >= 0 ? selection.end : text.length,
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
                              final nowStr = DateFormat('dd MMM, h:mm a').format(DateTime.now());
                              final text = contentCtrl.text;
                              final selection = contentCtrl.selection;
                              final toInsert = '\n[$nowStr] ';
                              final newText = text.isEmpty
                                  ? '[$nowStr] '
                                  : text.replaceRange(
                                      selection.start >= 0 ? selection.start : text.length,
                                      selection.end >= 0 ? selection.end : text.length,
                                      toInsert,
                                    );
                              contentCtrl.text = newText;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Content Input Field
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceSecondary
                            : AppColors.surfaceSecondary,
                        borderRadius: AppRadius.radiusLg,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                        ),
                      ),
                      child: TextField(
                        controller: contentCtrl,
                        maxLines: 7,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: isDark
                              ? AppColors.darkTextHeading
                              : AppColors.textHeading,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Write your thoughts, checklists, or plans...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quick Tag Chips (Selectable)
                    Text(
                      'Tags:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextCaption
                            : AppColors.textCaption,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ..._suggestedTags.map((tag) {
                          final isTagActive = activeTags.contains(tag);
                          return FilterChip(
                            selected: isTagActive,
                            label: Text(tag, style: const TextStyle(fontSize: 11)),
                            selectedColor: Color(selectedColor).withValues(alpha: 0.2),
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
                          child: TextField(
                            controller: customTagCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Add custom tag (e.g. @Meeting)',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            final custom = customTagCtrl.text.trim();
                            if (custom.isNotEmpty) {
                              final formatted = custom.startsWith('@')
                                  ? custom
                                  : '@$custom';
                              if (!activeTags.contains(formatted)) {
                                setSheetState(() => activeTags.add(formatted));
                              }
                              customTagCtrl.clear();
                            }
                          },
                          child: const Text('Add Tag'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Save / Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: () {
                          final title = titleCtrl.text.trim();
                          final content = contentCtrl.text.trim();

                          if (title.isEmpty && content.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a title or content.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          final effectiveTitle =
                              title.isNotEmpty ? title : 'Untitled Note';
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
                            borderRadius: AppRadius.radiusMd,
                          ),
                        ),
                        icon: const Icon(Icons.check_rounded),
                        label: Text(
                          isEditing ? 'Save Changes' : 'Create Note',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: onTap,
    );
  }
}
