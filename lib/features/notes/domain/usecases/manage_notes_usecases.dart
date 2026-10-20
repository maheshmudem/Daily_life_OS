import '../repositories/notes_repository.dart';

class AddNoteUseCase {
  final NotesRepository _repository;

  const AddNoteUseCase(this._repository);

  Future<void> call({
    required String title,
    required String content,
    required int colorValue,
    String tags = '',
  }) =>
      _repository.addNote(
        title: title,
        content: content,
        colorValue: colorValue,
        tags: tags,
      );
}

class UpdateNoteUseCase {
  final NotesRepository _repository;

  const UpdateNoteUseCase(this._repository);

  Future<void> call(
    int id, {
    String? title,
    String? content,
    int? colorValue,
    String? tags,
  }) =>
      _repository.updateNote(
        id,
        title: title,
        content: content,
        colorValue: colorValue,
        tags: tags,
      );
}

class DeleteNoteUseCase {
  final NotesRepository _repository;

  const DeleteNoteUseCase(this._repository);

  Future<void> call(int id) => _repository.deleteNote(id);
}

class TogglePinNoteUseCase {
  final NotesRepository _repository;

  const TogglePinNoteUseCase(this._repository);

  Future<void> call(int id) => _repository.togglePin(id);
}
