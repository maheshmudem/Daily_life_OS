import 'package:equatable/equatable.dart';

abstract class NotesEvent extends Equatable {
  const NotesEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotes extends NotesEvent {
  const LoadNotes();
}

class DeleteNote extends NotesEvent {
  final int id;
  const DeleteNote(this.id);
  @override
  List<Object?> get props => [id];
}

class TogglePinNote extends NotesEvent {
  final int id;
  const TogglePinNote(this.id);
  @override
  List<Object?> get props => [id];
}

class AddNote extends NotesEvent {
  final String title;
  final String content;
  final int colorValue;
  final String tags;
  const AddNote({
    required this.title,
    required this.content,
    required this.colorValue,
    this.tags = '',
  });
  @override
  List<Object?> get props => [title, content, colorValue, tags];
}

class UpdateNote extends NotesEvent {
  final int id;
  final String title;
  final String content;
  final int colorValue;
  final String tags;

  const UpdateNote({
    required this.id,
    required this.title,
    required this.content,
    required this.colorValue,
    this.tags = '',
  });

  @override
  List<Object?> get props => [id, title, content, colorValue, tags];
}
