import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/constants/string_constants.dart';

/// Asset account types shown in the Total Assets breakdown.
class MoneyAccountType {
  MoneyAccountType._();

  static const String cash = 'cash';
  static const String savings = 'savings';
  static const String investment = 'investment';

  static const List<String> values = [cash, savings, investment];

  static String label(String type) {
    switch (type) {
      case savings:
        return StringConstants.savings;
      case investment:
        return StringConstants.investments;
      case cash:
      default:
        return StringConstants.cash;
    }
  }

  static IconData icon(String type) {
    switch (type) {
      case savings:
        return Icons.savings_rounded;
      case investment:
        return Icons.trending_up_rounded;
      case cash:
      default:
        return Icons.payments_rounded;
    }
  }

  static Color color(String type) {
    switch (type) {
      case savings:
        return AppColors.moneyAssetSavings;
      case investment:
        return AppColors.moneyAssetInvest;
      case cash:
      default:
        return AppColors.moneyAssetCash;
    }
  }
}

/// A user-maintained asset account (cash wallet, savings, investments).
class MoneyAccountEntity extends Equatable {
  final int id;
  final String name;
  final String type; // MoneyAccountType value
  final double balance;
  final int colorValue;
  final int iconCodePoint;

  const MoneyAccountEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.colorValue,
    required this.iconCodePoint,
  });

  Color get color => Color(colorValue);

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  String get typeLabel => MoneyAccountType.label(type);

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    balance,
    colorValue,
    iconCodePoint,
  ];
}
