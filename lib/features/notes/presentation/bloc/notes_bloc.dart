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
    if (state is! NotesLoaded) {
      emit(NotesLoading());
    }
    try {
      final notes = await getNotesUseCase();
      emit(NotesLoaded(notes));
    } catch (e) {
      emit(NotesError(e.toString()));
    }
  }

  Future<void> _reloadSafely(Emitter<NotesState> emit) async {
    final notes = await getNotesUseCase();
    emit(NotesLoaded(notes));
  }

  Future<void> _onAdd(AddNote event, Emitter<NotesState> emit) async {
    try {
      await addNoteUseCase(
        title: event.title,
        content: event.content,
        colorValue: event.colorValue,
        tags: event.tags,
        isPinned: event.isPinned,
      );
      await _reloadSafely(emit);
    } catch (e) {
      if (state is! NotesLoaded) {
        emit(NotesError(e.toString()));
      }
    }
  }

  Future<void> _onUpdate(UpdateNote event, Emitter<NotesState> emit) async {
    final previous = state;
    if (previous is NotesLoaded) {
      final parsedTags = event.tags
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      final optimistic = previous.notes.map((n) {
        if (n.id != event.id) return n;
        return n.copyWith(
          title: event.title,
          content: event.content,
          colorValue: event.colorValue,
          tags: parsedTags,
          isPinned: event.isPinned ?? n.isPinned,
        );
      }).toList();
      emit(NotesLoaded(optimistic));
    }
    try {
      await updateNoteUseCase(
        event.id,
        title: event.title,
        content: event.content,
        colorValue: event.colorValue,
        tags: event.tags,
        isPinned: event.isPinned,
      );
      await _reloadSafely(emit);
    } catch (e) {
      if (previous is NotesLoaded) {
        emit(previous);
      } else {
        emit(NotesError(e.toString()));
      }
    }
  }

  Future<void> _onDelete(DeleteNote event, Emitter<NotesState> emit) async {
    try {
      await deleteNoteUseCase(event.id);
      await _reloadSafely(emit);
    } catch (e) {
      if (state is! NotesLoaded) {
        emit(NotesError(e.toString()));
      }
    }
  }

  Future<void> _onTogglePin(
    TogglePinNote event,
    Emitter<NotesState> emit,
  ) async {
    final previous = state;
    if (previous is NotesLoaded) {
      final optimistic = previous.notes
          .map((n) => n.id == event.id ? n.copyWith(isPinned: !n.isPinned) : n)
          .toList();
      emit(NotesLoaded(optimistic));
    }
    try {
      await togglePinNoteUseCase(event.id);
      await _reloadSafely(emit);
    } catch (e) {
      if (previous is NotesLoaded) {
        emit(previous);
      } else {
        emit(NotesError(e.toString()));
      }
    }
  }
}
