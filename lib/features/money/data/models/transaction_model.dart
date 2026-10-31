import '../../../../core/database/app_database.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.title,
    required super.category,
    required super.amount,
    required super.mode,
    required super.iconCodePoint,
    required super.date,
    required super.type,
    super.note,
  });

  factory TransactionModel.fromDrift(Transaction row) {
    return TransactionModel(
      id: row.id,
      title: row.title,
      category: row.category,
      amount: row.amount,
      mode: row.mode,
      iconCodePoint: row.iconCodePoint,
      date: row.date,
      type: row.type,
      note: row.note,
    );
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      title: entity.title,
      category: entity.category,
      amount: entity.amount,
      mode: entity.mode,
      iconCodePoint: entity.iconCodePoint,
      date: entity.date,
      type: entity.type,
      note: entity.note,
    );
  }
}

class BudgetModel extends BudgetEntity {
  const BudgetModel({
    required super.monthlyBudget,
    required super.fixedBills,
    required super.totalSpent,
  });

  factory BudgetModel.fromValues({
    required double monthlyBudget,
    required double fixedBills,
    required double totalSpent,
  }) {
    return BudgetModel(
      monthlyBudget: monthlyBudget,
      fixedBills: fixedBills,
      totalSpent: totalSpent,
    );
  }
}
