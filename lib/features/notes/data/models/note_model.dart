import '../../../../core/database/app_database.dart';
import '../../domain/entities/note_entity.dart';

class NoteModel extends NoteEntity {
  const NoteModel({
    required super.id,
    required super.title,
    required super.content,
    required super.colorValue,
    required super.isPinned,
    required super.tags,
    required super.createdAt,
    required super.updatedAt,
  });

  factory NoteModel.fromDrift(Note row) {
    return NoteModel(
      id: row.id,
      title: row.title,
      content: row.content,
      colorValue: row.colorValue,
      isPinned: row.isPinned,
      tags: row.tags.split(',').where((t) => t.isNotEmpty).toList(),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  factory NoteModel.fromEntity(NoteEntity entity) {
    return NoteModel(
      id: entity.id,
      title: entity.title,
      content: entity.content,
      colorValue: entity.colorValue,
      isPinned: entity.isPinned,
      tags: entity.tags,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
