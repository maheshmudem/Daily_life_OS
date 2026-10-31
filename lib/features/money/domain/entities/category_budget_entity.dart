import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/string_constants.dart';
import 'money_category.dart';

/// Budget health of a single category for the selected month.
enum BudgetStatus { onTrack, nearLimit, overBudget, noLimit }

/// Monthly limit for one expense category plus the derived spend.
class CategoryBudgetEntity extends Equatable {
  /// Progress ratio at which a category is flagged as "Near limit".
  static const double nearLimitThreshold = 0.8;

  final String category; // MoneyCategory key
  final double monthlyLimit; // 0 = no limit set
  final double spent;

  const CategoryBudgetEntity({
    required this.category,
    required this.monthlyLimit,
    required this.spent,
  });

  MoneyCategory get categoryInfo => MoneyCategory.resolve(category);

  bool get hasLimit => monthlyLimit > 0;

  /// 0..1 clamped progress.
  double get progress =>
      hasLimit ? (spent / monthlyLimit).clamp(0.0, 1.0) : 0.0;

  /// Unclamped percentage used (can exceed 100).
  double get percentUsed => hasLimit ? (spent / monthlyLimit) * 100 : 0;

  double get remaining => (monthlyLimit - spent).clamp(0.0, double.infinity);

  double get overBy => isOverBudget ? spent - monthlyLimit : 0;

  bool get isOverBudget => hasLimit && spent > monthlyLimit;

  bool get isNearLimit =>
      hasLimit && !isOverBudget && progress >= nearLimitThreshold;

  BudgetStatus get status {
    if (!hasLimit) return BudgetStatus.noLimit;
    if (isOverBudget) return BudgetStatus.overBudget;
    if (isNearLimit) return BudgetStatus.nearLimit;
    return BudgetStatus.onTrack;
  }

  String get statusLabel {
    switch (status) {
      case BudgetStatus.onTrack:
        return StringConstants.onTrack;
      case BudgetStatus.nearLimit:
        return StringConstants.nearLimit;
      case BudgetStatus.overBudget:
        return StringConstants.overBudget;
      case BudgetStatus.noLimit:
        return StringConstants.noLimitSet;
    }
  }

  IconData get icon => categoryInfo.icon;

  CategoryBudgetEntity copyWith({double? monthlyLimit, double? spent}) {
    return CategoryBudgetEntity(
      category: category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      spent: spent ?? this.spent,
    );
  }

  @override
  List<Object?> get props => [category, monthlyLimit, spent];
}
