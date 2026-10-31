import 'package:flutter/material.dart';
import '../../domain/entities/countdown_item_entity.dart';
import '../../../../config/theme/app_colors.dart';

class CountdownItemModel extends CountdownItemEntity {
  const CountdownItemModel({
    required super.id,
    required super.title,
    required super.date,
    required super.category,
    required super.colorValue,
    required super.iconCodePoint,
    super.notes = '',
    super.remindAdvance = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'category': category,
    'colorValue': colorValue,
    'iconCodePoint': iconCodePoint,
    'notes': notes,
    'remindAdvance': remindAdvance,
  };

  factory CountdownItemModel.fromJson(
    Map<String, dynamic> json,
  ) => CountdownItemModel(
    id:
        json['id'] as String? ??
        DateTime.now().millisecondsSinceEpoch.toString(),
    title: json['title'] as String? ?? '',
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    category: json['category'] as String? ?? 'Birthday',
    colorValue: json['colorValue'] as int? ?? AppColors.moduleNotes.toARGB32(),
    iconCodePoint:
        json['iconCodePoint'] as int? ?? Icons.cake_rounded.codePoint,
    notes: json['notes'] as String? ?? '',
    remindAdvance: json['remindAdvance'] as bool? ?? true,
  );

  factory CountdownItemModel.fromEntity(CountdownItemEntity entity) =>
      CountdownItemModel(
        id: entity.id,
        title: entity.title,
        date: entity.date,
        category: entity.category,
        colorValue: entity.colorValue,
        iconCodePoint: entity.iconCodePoint,
        notes: entity.notes,
        remindAdvance: entity.remindAdvance,
      );
}
