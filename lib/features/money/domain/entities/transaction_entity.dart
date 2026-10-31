import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/date_utils.dart';
import 'money_category.dart';

class TransactionEntity extends Equatable {
  final int id;
  final String title;
  final String category;
  final double amount;
  final String mode;
  final int iconCodePoint;
  final String date;
  final String type; // 'expense' / 'income'
  final String? note;

  const TransactionEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.mode,
    required this.iconCodePoint,
    required this.date,
    required this.type,
    this.note,
  });

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  /// Parsed [date]; falls back to epoch for malformed rows so sorting stays stable.
  DateTime get dateTime =>
      DateTime.tryParse(date) ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Unified category metadata (label, icon, colour) for this transaction.
  MoneyCategory get categoryInfo =>
      MoneyCategory.resolve(category, isIncome: isIncome);

  /// +amount for income, -amount for expense.
  double get signedAmount => isIncome ? amount : -amount;

  String get formattedDate {
    final dt = DateTime.tryParse(date);
    if (dt == null) return date;
    return AppDateUtils.formatTransactionDate(dt);
  }

  TransactionEntity copyWith({
    String? title,
    String? category,
    double? amount,
    String? mode,
    int? iconCodePoint,
    String? date,
    String? type,
    String? note,
  }) {
    return TransactionEntity(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      mode: mode ?? this.mode,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      date: date ?? this.date,
      type: type ?? this.type,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    category,
    amount,
    mode,
    date,
    type,
    note,
  ];
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
    return available > 0
        ? (available / (daysRemaining > 0 ? daysRemaining : 1))
        : 0;
  }

  @override
  List<Object?> get props => [monthlyBudget, fixedBills, totalSpent];
}
