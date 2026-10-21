import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_notes_usecase.dart';
import '../../domain/usecases/manage_notes_usecases.dart';
import 'notes_event.dart';
import 'notes_state.dart';

export 'notes_event.dart';
export 'notes_state.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final GetNotesUseCase getNotesUseCase;
  final AddNoteUseCase addNoteUseCase;
  final UpdateNoteUseCase updateNoteUseCase;
  final DeleteNoteUseCase deleteNoteUseCase;
  final TogglePinNoteUseCase togglePinNoteUseCase;

  NotesBloc({
    required this.getNotesUseCase,
    required this.addNoteUseCase,
    required this.updateNoteUseCase,
    required this.deleteNoteUseCase,
    required this.togglePinNoteUseCase,
  }) : super(NotesInitial()) {
    on<LoadNotes>(_onLoad);
    on<AddNote>(_onAdd);
    on<UpdateNote>(_onUpdate);
    on<DeleteNote>(_onDelete);
    on<TogglePinNote>(_onTogglePin);
  }

  Future<void> _onLoad(LoadNotes event, Emitter<NotesState> emit) async {
    emit(NotesLoading());
    try {
      final notes = await getNotesUseCase();
      emit(NotesLoaded(notes));
    } catch (e) {
      emit(NotesError(e.toString()));
    }
  }

  Future<void> _onAdd(AddNote event, Emitter<NotesState> emit) async {
    await addNoteUseCase(
      title: event.title,
      content: event.content,
      colorValue: event.colorValue,
      tags: event.tags,
    );
    final notes = await getNotesUseCase();
    emit(NotesLoaded(notes));
  }

  Future<void> _onUpdate(UpdateNote event, Emitter<NotesState> emit) async {
    await updateNoteUseCase(
      event.id,
      title: event.title,
      content: event.content,
      colorValue: event.colorValue,
      tags: event.tags,
    );
    final notes = await getNotesUseCase();
    emit(NotesLoaded(notes));
  }

  Future<void> _onDelete(DeleteNote event, Emitter<NotesState> emit) async {
    await deleteNoteUseCase(event.id);
    final notes = await getNotesUseCase();
    emit(NotesLoaded(notes));
  }

  Future<void> _onTogglePin(TogglePinNote event, Emitter<NotesState> emit) async {
    await togglePinNoteUseCase(event.id);
    final notes = await getNotesUseCase();
    emit(NotesLoaded(notes));
  }
}
