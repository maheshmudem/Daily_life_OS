import 'package:drift/drift.dart' hide Column;
import '../../../../core/database/app_database.dart';
import '../models/note_model.dart';

abstract class NotesLocalDataSource {
  Future<List<NoteModel>> getNotes();
  Future<void> addNote({
    required String title,
    required String content,
    required int colorValue,
    String tags = '',
  });
  Future<void> updateNote(
    int id, {
    String? title,
    String? content,
    int? colorValue,
    String? tags,
  });
  Future<void> deleteNote(int id);
  Future<void> togglePin(int id);
}

class NotesLocalDataSourceImpl implements NotesLocalDataSource {
  final AppDatabase _db;

  NotesLocalDataSourceImpl(this._db);

  @override
  Future<List<NoteModel>> getNotes() async {
    final rows =
        await (_db.select(_db.notes)..orderBy([
              (t) => OrderingTerm.desc(t.isPinned),
              (t) => OrderingTerm.desc(t.updatedAt),
            ]))
            .get();
    return rows.map(NoteModel.fromDrift).toList();
  }

  @override
  Future<void> addNote({
    required String title,
    required String content,
    required int colorValue,
    String tags = '',
  }) async {
    final now = DateTime.now().toIso8601String();
    await _db
        .into(_db.notes)
        .insert(
          NotesCompanion.insert(
            title: title,
            content: content,
            colorValue: colorValue,
            tags: Value(tags),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> updateNote(
    int id, {
    String? title,
    String? content,
    int? colorValue,
    String? tags,
  }) async {
    final now = DateTime.now().toIso8601String();
    await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        title: title != null ? Value(title) : const Value.absent(),
        content: content != null ? Value(content) : const Value.absent(),
        colorValue: colorValue != null
            ? Value(colorValue)
            : const Value.absent(),
        tags: tags != null ? Value(tags) : const Value.absent(),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> deleteNote(int id) async {
    await (_db.delete(_db.notes)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> togglePin(int id) async {
    final note = await (_db.select(
      _db.notes,
    )..where((t) => t.id.equals(id))).getSingle();
    await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(isPinned: Value(!note.isPinned)),
    );
  }
}
