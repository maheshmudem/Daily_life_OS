import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class PlannerItemEntity extends Equatable {
  final int id;
  final String title;
  final String date;
  final String? startTime;
  final String? endTime;
  final String category;
  final int colorValue;
  final int iconCodePoint;
  final bool isDone;
  final String notes;

  const PlannerItemEntity({
    required this.id,
    required this.title,
    required this.date,
    this.startTime,
    this.endTime,
    required this.category,
    required this.colorValue,
    required this.iconCodePoint,
    required this.isDone,
    required this.notes,
  });

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  String get timeRange {
    if (startTime != null && endTime != null) return '$startTime – $endTime';
    if (startTime != null) return startTime!;
    return '';
  }

  @override
  List<Object?> get props => [id, isDone];
}
