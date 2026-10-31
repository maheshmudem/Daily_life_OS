import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';

/// Single source of truth for Money categories (expense + income).
///
/// Transactions store the category [key] (e.g. `food`). Legacy rows that were
/// saved with display names (e.g. `Food & Groceries`, `Travel`) are mapped via
/// [MoneyCategory.resolve] so old data keeps rendering correctly.
class MoneyCategory extends Equatable {
  final String key;
  final String label;
  final String shortLabel;
  final IconData icon;
  final Color color;
  final bool isIncome;

  const MoneyCategory({
    required this.key,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.color,
    this.isIncome = false,
  });

  // ── Expense categories ────────────────────────────────────────────────────
  static const food = MoneyCategory(
    key: 'food',
    label: 'Food & Dining',
    shortLabel: 'Food',
    icon: Icons.restaurant_rounded,
    color: AppColors.moneyCatFood,
  );
  static const transport = MoneyCategory(
    key: 'transport',
    label: 'Transport',
    shortLabel: 'Transport',
    icon: Icons.directions_car_rounded,
    color: AppColors.moneyCatTransport,
  );
  static const shopping = MoneyCategory(
    key: 'shopping',
    label: 'Shopping',
    shortLabel: 'Shopping',
    icon: Icons.shopping_bag_rounded,
    color: AppColors.moneyCatShopping,
  );
  static const health = MoneyCategory(
    key: 'health',
    label: 'Health',
    shortLabel: 'Health',
    icon: Icons.local_pharmacy_rounded,
    color: AppColors.moneyCatHealth,
  );
  static const entertainment = MoneyCategory(
    key: 'entertainment',
    label: 'Entertainment',
    shortLabel: 'Fun',
    icon: Icons.play_circle_rounded,
    color: AppColors.moneyCatEntertainment,
  );
  static const bills = MoneyCategory(
    key: 'bills',
    label: 'Bills & Utilities',
    shortLabel: 'Bills',
    icon: Icons.receipt_long_rounded,
    color: AppColors.moneyCatBills,
  );
  static const travel = MoneyCategory(
    key: 'travel',
    label: 'Travel',
    shortLabel: 'Travel',
    icon: Icons.flight_rounded,
    color: AppColors.moneyCatTravel,
  );
  static const other = MoneyCategory(
    key: 'other',
    label: 'Other',
    shortLabel: 'Other',
    icon: Icons.more_horiz_rounded,
    color: AppColors.moneyCatOther,
  );

  // ── Income categories ─────────────────────────────────────────────────────
  static const salary = MoneyCategory(
    key: 'salary',
    label: 'Salary',
    shortLabel: 'Salary',
    icon: Icons.account_balance_rounded,
    color: AppColors.moneyCatIncome,
    isIncome: true,
  );
  static const business = MoneyCategory(
    key: 'business',
    label: 'Business & Freelance',
    shortLabel: 'Freelance',
    icon: Icons.work_rounded,
    color: AppColors.moneyCatIncome,
    isIncome: true,
  );
  static const investmentReturn = MoneyCategory(
    key: 'investment_return',
    label: 'Investment Returns',
    shortLabel: 'Returns',
    icon: Icons.trending_up_rounded,
    color: AppColors.moneyCatIncome,
    isIncome: true,
  );
  static const gift = MoneyCategory(
    key: 'gift',
    label: 'Gifts',
    shortLabel: 'Gift',
    icon: Icons.card_giftcard_rounded,
    color: AppColors.moneyCatIncome,
    isIncome: true,
  );
  static const otherIncome = MoneyCategory(
    key: 'other_income',
    label: 'Other Income',
    shortLabel: 'Other',
    icon: Icons.add_card_rounded,
    color: AppColors.moneyCatIncome,
    isIncome: true,
  );

  static const List<MoneyCategory> expenseCategories = [
    food,
    transport,
    shopping,
    health,
    entertainment,
    bills,
    travel,
    other,
  ];

  static const List<MoneyCategory> incomeCategories = [
    salary,
    business,
    investmentReturn,
    gift,
    otherIncome,
  ];

  static const List<MoneyCategory> all = [
    ...expenseCategories,
    ...incomeCategories,
  ];

  /// Legacy / free-text names → category key.
  static const Map<String, String> _aliases = {
    'food & groceries': 'food',
    'food & drinks': 'food',
    'food & dining': 'food',
    'groceries': 'food',
    'dining': 'food',
    'transport': 'transport',
    'transportation': 'transport',
    'fuel': 'transport',
    'bills & utilities': 'bills',
    'utilities': 'bills',
    'medical': 'health',
    'fun': 'entertainment',
    'movies': 'entertainment',
    'income': 'salary',
    'freelance': 'business',
  };

  /// Resolves a stored category string (key, label or legacy alias).
  /// Unknown values fall back to [other] (or [otherIncome] for income).
  static MoneyCategory resolve(String raw, {bool isIncome = false}) {
    final normalized = raw.trim().toLowerCase();
    for (final c in all) {
      if (c.key == normalized ||
          c.label.toLowerCase() == normalized ||
          c.shortLabel.toLowerCase() == normalized) {
        return c;
      }
    }
    final aliasKey = _aliases[normalized];
    if (aliasKey != null) {
      return all.firstWhere((c) => c.key == aliasKey);
    }
    return isIncome ? otherIncome : other;
  }

  @override
  List<Object?> get props => [key];
}
