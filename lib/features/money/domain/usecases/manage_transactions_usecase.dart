import '../repositories/money_repository.dart';

class AddTransactionUseCase {
  final MoneyRepository _repository;

  const AddTransactionUseCase(this._repository);

  Future<void> call({
    required String title,
    required String category,
    required double amount,
    required String mode,
    required int iconCodePoint,
    String type = 'expense',
  }) =>
      _repository.addTransaction(
        title: title,
        category: category,
        amount: amount,
        mode: mode,
        iconCodePoint: iconCodePoint,
        type: type,
      );
}

class UpdateBudgetUseCase {
  final MoneyRepository _repository;

  const UpdateBudgetUseCase(this._repository);

  Future<void> call(double monthlyBudget, double fixedBills) =>
      _repository.updateBudget(monthlyBudget, fixedBills);
}
