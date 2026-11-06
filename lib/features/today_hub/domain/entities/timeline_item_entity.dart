import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class TimelineItemEntity extends Equatable {
  final int id;
  final String time;
  final String title;
  final String category;
  final int colorValue;
  final int iconCodePoint;
  final bool isDone;
  final String action;
  final String date;

  const TimelineItemEntity({
    required this.id,
    required this.time,
    required this.title,
    required this.category,
    required this.colorValue,
    required this.iconCodePoint,
    required this.isDone,
    required this.action,
    required this.date,
  });

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  TimelineItemEntity copyWith({
    int? id,
    String? time,
    String? title,
    String? category,
    int? colorValue,
    int? iconCodePoint,
    bool? isDone,
    String? action,
    String? date,
  }) {
    return TimelineItemEntity(
      id: id ?? this.id,
      time: time ?? this.time,
      title: title ?? this.title,
      category: category ?? this.category,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      isDone: isDone ?? this.isDone,
      action: action ?? this.action,
      date: date ?? this.date,
    );
  }

  @override
  List<Object?> get props => [
    id,
    time,
    title,
    category,
    colorValue,
    iconCodePoint,
    isDone,
    action,
    date,
  ];
}
