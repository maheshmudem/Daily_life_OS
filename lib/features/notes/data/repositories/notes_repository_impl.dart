import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/notes_repository.dart';
import '../datasources/notes_local_datasource.dart';

class NotesRepositoryImpl implements NotesRepository {
  final NotesLocalDataSource _localDataSource;

  NotesRepositoryImpl(this._localDataSource);

  @override
  Future<List<NoteEntity>> getNotes() => _localDataSource.getNotes();

  @override
  Future<void> addNote({
    required String title,
    required String content,
    required int colorValue,
    String tags = '',
  }) =>
      _localDataSource.addNote(
        title: title,
        content: content,
        colorValue: colorValue,
        tags: tags,
      );

  @override
  Future<void> updateNote(int id, {String? title, String? content, int? colorValue, String? tags}) =>
      _localDataSource.updateNote(id, title: title, content: content, colorValue: colorValue, tags: tags);

  @override
  Future<void> deleteNote(int id) => _localDataSource.deleteNote(id);

  @override
  Future<void> togglePin(int id) => _localDataSource.togglePin(id);
}
