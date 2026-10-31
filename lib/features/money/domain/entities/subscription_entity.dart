import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SubscriptionEntity extends Equatable {
  final int id;
  final String name;
  final double amount;
  final String renewalDate;
  final bool autoKillEnabled;
  final int iconCodePoint;

  const SubscriptionEntity({
    required this.id,
    required this.name,
    required this.amount,
    required this.renewalDate,
    required this.autoKillEnabled,
    required this.iconCodePoint,
  });

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  String get renewalLabel {
    try {
      final dt = DateTime.parse(renewalDate);
      final now = DateTime.now();
      final diff = dt.difference(now).inDays;
      final month = _monthAbbr(dt.month);
      return '$month ${dt.day} (In $diff days)';
    } catch (_) {
      return renewalDate;
    }
  }

  String _monthAbbr(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }

  @override
  List<Object?> get props => [id, autoKillEnabled];
}

class IouEntity extends Equatable {
  final int id;
  final String person;
  final double amount;
  final String type; // 'lent' / 'borrowed'
  final String note;
  final String date;
  final bool isSettled;

  const IouEntity({
    required this.id,
    required this.person,
    required this.amount,
    required this.type,
    required this.note,
    required this.date,
    required this.isSettled,
  });

  bool get isLent => type == 'lent';
  String get typeLabel => isLent ? 'Lent to' : 'Borrowed from';

  @override
  List<Object?> get props => [id, isSettled];
}
