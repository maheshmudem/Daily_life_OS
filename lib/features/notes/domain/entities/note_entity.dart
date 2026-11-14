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

  static bool isChecklistLine(String line) {
    final trimmed = line.trimLeft();
    return trimmed.startsWith('[ ] ') ||
        trimmed.startsWith('[x] ') ||
        trimmed.startsWith('[X] ');
  }

  static bool isCheckedLine(String line) {
    final trimmed = line.trimLeft();
    return trimmed.startsWith('[x] ') || trimmed.startsWith('[X] ');
  }

  bool get hasChecklist => content.split('\n').any(isChecklistLine);

  int get checklistTotalCount =>
      content.split('\n').where(isChecklistLine).length;

  int get checklistDoneCount => content.split('\n').where(isCheckedLine).length;

  double get checklistProgress {
    final total = checklistTotalCount;
    if (total == 0) return 0.0;
    return (checklistDoneCount / total).clamp(0.0, 1.0);
  }

  int get wordCount {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  NoteEntity copyWith({
    int? id,
    String? title,
    String? content,
    int? colorValue,
    bool? isPinned,
    List<String>? tags,
    String? createdAt,
    String? updatedAt,
  }) {
    return NoteEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      colorValue: colorValue ?? this.colorValue,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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
