import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/features/notes/data/datasources/notes_local_datasource.dart';

void main() {
  late AppDatabase db;
  late NotesLocalDataSource dataSource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dataSource = NotesLocalDataSourceImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'NotesLocalDataSource performs full CRUD, pin on create/update, and pin toggle',
    () async {
      // 1. Initial list empty
      final initial = await dataSource.getNotes();
      expect(initial, isEmpty);

      // 2. Add note (unpinned)
      await dataSource.addNote(
        title: 'App Ideas',
        content: 'Personal OS with cross module actions',
        colorValue: 0xFFF59E0B,
        tags: '@Ideas,@Work',
      );

      final notes = await dataSource.getNotes();
      expect(notes.length, 1);
      expect(notes.first.title, 'App Ideas');
      expect(notes.first.isPinned, false);

      // 3. Pin note via togglePin
      await dataSource.togglePin(notes.first.id);
      final pinned = await dataSource.getNotes();
      expect(pinned.first.isPinned, true);

      // 4. Update note including explicit isPinned flag
      await dataSource.updateNote(
        pinned.first.id,
        title: 'App Ideas V2',
        content: 'Updated content description',
        isPinned: false,
      );
      final updated = await dataSource.getNotes();
      expect(updated.first.title, 'App Ideas V2');
      expect(updated.first.content, 'Updated content description');
      expect(updated.first.isPinned, false);

      // 5. Add pre-pinned note directly
      await dataSource.addNote(
        title: 'Pinned Manifesto',
        content: '[ ] Ship clean Notes UI',
        colorValue: 0xFF0EA5E9,
        tags: '@Work',
        isPinned: true,
      );
      final withPinned = await dataSource.getNotes();
      expect(withPinned.first.title, 'Pinned Manifesto');
      expect(withPinned.first.isPinned, true);
      expect(withPinned.first.hasChecklist, true);
      expect(withPinned.first.checklistTotalCount, 1);

      // 6. Delete notes
      for (final item in withPinned) {
        await dataSource.deleteNote(item.id);
      }
      final remaining = await dataSource.getNotes();
      expect(remaining, isEmpty);
    },
  );
}
