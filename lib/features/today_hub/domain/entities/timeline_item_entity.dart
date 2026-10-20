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

  @override
  List<Object?> get props => [id, isDone];
}
