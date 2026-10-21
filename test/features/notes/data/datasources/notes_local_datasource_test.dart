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

  test('NotesLocalDataSource performs full CRUD and pin toggle', () async {
    // 1. Initial list empty
    final initial = await dataSource.getNotes();
    expect(initial, isEmpty);

    // 2. Add note
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

    // 3. Pin note
    await dataSource.togglePin(notes.first.id);
    final pinned = await dataSource.getNotes();
    expect(pinned.first.isPinned, true);

    // 4. Update note
    await dataSource.updateNote(
      pinned.first.id,
      title: 'App Ideas V2',
      content: 'Updated content description',
    );
    final updated = await dataSource.getNotes();
    expect(updated.first.title, 'App Ideas V2');
    expect(updated.first.content, 'Updated content description');

    // 5. Delete note
    await dataSource.deleteNote(updated.first.id);
    final remaining = await dataSource.getNotes();
    expect(remaining, isEmpty);
  });
}
