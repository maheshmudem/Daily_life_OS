import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class HabitEntity extends Equatable {
  final int id;
  final String title;
  final int iconCodePoint;
  final int colorValue;
  final int streakDays;
  final bool isDoneToday;
  final String? lastCompletedDate;
  final String createdAt;

  const HabitEntity({
    required this.id,
    required this.title,
    required this.iconCodePoint,
    required this.colorValue,
    required this.streakDays,
    required this.isDoneToday,
    this.lastCompletedDate,
    required this.createdAt,
  });

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  HabitEntity copyWith({bool? isDoneToday, int? streakDays, String? lastCompletedDate}) {
    return HabitEntity(
      id: id,
      title: title,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      streakDays: streakDays ?? this.streakDays,
      isDoneToday: isDoneToday ?? this.isDoneToday,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, title, isDoneToday, streakDays];
}
