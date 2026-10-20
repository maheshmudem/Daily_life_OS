import '../entities/note_entity.dart';

abstract class NotesRepository {
  Future<List<NoteEntity>> getNotes();
  Future<void> addNote({
    required String title,
    required String content,
    required int colorValue,
    String tags = '',
  });
  Future<void> updateNote(int id, {String? title, String? content, int? colorValue, String? tags});
  Future<void> deleteNote(int id);
  Future<void> togglePin(int id);
}
