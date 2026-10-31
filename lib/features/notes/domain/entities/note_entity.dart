import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class NoteEntity extends Equatable {
  final int id;
  final String title;
  final String content;
  final int colorValue;
  final bool isPinned;
  final List<String> tags;
  final String createdAt;
  final String updatedAt;

  const NoteEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.colorValue,
    required this.isPinned,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  Color get color => Color(colorValue);

  String get previewContent {
    final lines = content.split('\n');
    return lines.take(3).join('\n');
  }

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    colorValue,
    isPinned,
    tags,
    createdAt,
    updatedAt,
  ];
}
