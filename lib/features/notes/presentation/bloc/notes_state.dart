import 'package:equatable/equatable.dart';
import '../../domain/entities/note_entity.dart';

abstract class NotesState extends Equatable {
  const NotesState();
  @override
  List<Object?> get props => [];
}

class NotesInitial extends NotesState {}

class NotesLoading extends NotesState {}

class NotesLoaded extends NotesState {
  final List<NoteEntity> notes;
  const NotesLoaded(this.notes);
  List<NoteEntity> get pinned => notes.where((n) => n.isPinned).toList();
  List<NoteEntity> get unpinned => notes.where((n) => !n.isPinned).toList();
  @override
  List<Object?> get props => [notes];
}

class NotesError extends NotesState {
  final String message;
  const NotesError(this.message);
  @override
  List<Object?> get props => [message];
}
