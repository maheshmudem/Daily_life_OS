import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class TransactionEntity extends Equatable {
  final int id;
  final String title;
  final String category;
  final double amount;
  final String mode;
  final int iconCodePoint;
  final String date;
  final String type; // 'expense' / 'income'

  const TransactionEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.mode,
    required this.iconCodePoint,
    required this.date,
    required this.type,
  });

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  bool get isExpense => type == 'expense';

  String get formattedDate {
    try {
      final dt = DateTime.parse(date);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inHours < 24 && dt.day == now.day) {
        return 'Today, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour < 12 ? 'AM' : 'PM'}';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return date;
    }
  }

  @override
  List<Object?> get props => [id, amount, date];
}

class BudgetEntity extends Equatable {
  final double monthlyBudget;
  final double fixedBills;
  final double totalSpent;

  const BudgetEntity({
    required this.monthlyBudget,
    required this.fixedBills,
    required this.totalSpent,
  });

  int get daysRemaining {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    return lastDay.day - now.day;
  }

  double get dailySafeSpend {
    final available = monthlyBudget - fixedBills - totalSpent;
    return available > 0 ? (available / (daysRemaining > 0 ? daysRemaining : 1)) : 0;
  }

  @override
  List<Object?> get props => [monthlyBudget, fixedBills, totalSpent];
}
