import 'package:equatable/equatable.dart';

class CountdownItemEntity extends Equatable {
  final String id;
  final String title;
  final DateTime date;
  final String category;
  final int colorValue;
  final int iconCodePoint;
  final String notes;
  final bool remindAdvance;

  const CountdownItemEntity({
    required this.id,
    required this.title,
    required this.date,
    required this.category,
    required this.colorValue,
    required this.iconCodePoint,
    this.notes = '',
    this.remindAdvance = true,
  });

  CountdownItemEntity copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? category,
    int? colorValue,
    int? iconCodePoint,
    String? notes,
    bool? remindAdvance,
  }) {
    return CountdownItemEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      category: category ?? this.category,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      notes: notes ?? this.notes,
      remindAdvance: remindAdvance ?? this.remindAdvance,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    date,
    category,
    colorValue,
    iconCodePoint,
    notes,
    remindAdvance,
  ];
}
