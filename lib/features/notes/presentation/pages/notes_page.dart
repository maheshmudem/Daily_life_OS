import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/widgets/app_shimmer_loader.dart';
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
  final TextEditingController _scratchpadController = TextEditingController(
    text: 'Locksmith phone: 98402-12345\nWiFi code for cafe: bean_roast_24',
  );

  String _selectedTag = 'All';

  @override
  void dispose() {
    _scratchpadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffoldBackground : AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          StringConstants.navNotes,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.moduleNotes),
            onPressed: () => _showAddNoteDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded, color: AppColors.moduleNotes),
            onPressed: () => QuickCaptureSheet.show(context, mode: QuickCaptureMode.scan),
          ),
          IconButton(
            icon: const Icon(Icons.mic_rounded, color: AppColors.voiceWaveform),
            onPressed: () => QuickCaptureSheet.show(context, mode: QuickCaptureMode.voice),
          ),
        ],
      ),
      body: BlocBuilder<NotesBloc, NotesState>(
        builder: (context, state) {
          if (state is NotesLoading || state is NotesInitial) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const AppShimmerLoader.card(height: 120),
                const SizedBox(height: 16),
                const AppShimmerLoader.card(height: 140),
                const SizedBox(height: 12),
                const AppShimmerLoader.card(height: 140),
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
    final allTags = {'All', ...state.notes.expand((n) => n.tags)};
    final filteredNotes = _selectedTag == 'All'
        ? state.notes
        : state.notes.where((n) => n.tags.contains(_selectedTag)).toList();

    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 90),
      children: [
        // Daily Scratchpad
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
            borderRadius: AppRadius.radiusLg,
            border: Border.all(
              color: AppColors.moduleNotes.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.moduleNotes.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.edit_note_rounded, color: AppColors.moduleNotes, size: 20),
                      SizedBox(width: 8),
                      Text(
                        StringConstants.dailyScratchpad,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ],
                  ),
                  Text(
                    'Auto-saves',
                    style: AppTextStyles.caption.copyWith(color: AppColors.moduleNotes),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _scratchpadController,
                maxLines: 3,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Tag filter strip
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

        // Pinned section
        if (state.pinned.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.push_pin_rounded, size: 14, color: AppColors.moduleNotes),
              AppSpacing.gapW8,
              const Text('Pinned', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 8),
          ...state.pinned.map((note) => _buildNoteCard(context, note, isDark)),
          const SizedBox(height: 8),
        ],

        // Notes list
        ...filteredNotes.where((n) => !n.isPinned).map((note) => _buildNoteCard(context, note, isDark)),
      ],
    );
  }

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
            color: isSelected ? AppColors.moduleNotes : (isDark ? AppColors.darkDivider : AppColors.divider),
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

  Widget _buildNoteCard(BuildContext context, NoteEntity note, bool isDark) {
    return Dismissible(
      key: Key('note_${note.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: AppRadius.radiusLg,
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      confirmDismiss: (_) async {
        context.read<NotesBloc>().add(DeleteNote(note.id));
        return false; // BLoC handles the delete + rebuild
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: note.isPinned
                ? note.color.withValues(alpha: 0.4)
                : (isDark ? AppColors.darkDivider : AppColors.divider),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.read<NotesBloc>().add(TogglePinNote(note.id)),
                  child: Icon(
                    note.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    size: 18,
                    color: note.isPinned ? AppColors.moduleNotes : (isDark ? AppColors.darkTextCaption : AppColors.textCaption),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.previewContent,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextBody : AppColors.textBody,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tags
                if (note.tags.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: note.tags
                        .take(2)
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.moduleNotes.withValues(alpha: 0.12),
                                borderRadius: AppRadius.radiusSm,
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.moduleNotes,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                // Cross-module converters
                Row(
                  children: [
                    _buildConverterButton(context, '-> Reminder', AppColors.moduleTime),
                    const SizedBox(width: 6),
                    _buildConverterButton(context, '-> Expense', AppColors.moduleMoney),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConverterButton(BuildContext context, String label, Color color) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Converting: $label'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadius.radiusSm,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Note', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isNotEmpty) {
                    context.read<NotesBloc>().add(AddNote(
                          title: titleCtrl.text.trim(),
                          content: contentCtrl.text.trim(),
                          colorValue: AppColors.moduleNotes.toARGB32(),
                        ));
                    Navigator.of(ctx).pop();
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.moduleNotes),
                child: const Text('Save Note'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
