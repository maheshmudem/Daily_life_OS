import '../entities/vault_item_entity.dart';
import '../repositories/vault_repository.dart';

class GetVaultPasswordsUseCase {
  final VaultRepository _repository;

  const GetVaultPasswordsUseCase(this._repository);

  Future<List<VaultPasswordEntity>> call() => _repository.getPasswords();
}

class GetVaultDocumentsUseCase {
  final VaultRepository _repository;

  const GetVaultDocumentsUseCase(this._repository);

  Future<List<VaultDocumentEntity>> call() => _repository.getDocuments();
}
