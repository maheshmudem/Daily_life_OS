import '../entities/note_entity.dart';
import '../repositories/notes_repository.dart';

class GetNotesUseCase {
  final NotesRepository _repository;

  const GetNotesUseCase(this._repository);

  Future<List<NoteEntity>> call() => _repository.getNotes();
}
