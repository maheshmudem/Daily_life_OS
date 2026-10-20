import '../../domain/entities/vault_item_entity.dart';
import '../../domain/repositories/vault_repository.dart';
import '../datasources/vault_local_datasource.dart';

class VaultRepositoryImpl implements VaultRepository {
  final VaultLocalDataSource _localDataSource;

  VaultRepositoryImpl(this._localDataSource);

  @override
  Future<List<VaultPasswordEntity>> getPasswords() =>
      _localDataSource.getPasswords();

  @override
  Future<List<VaultDocumentEntity>> getDocuments() =>
      _localDataSource.getDocuments();
}
