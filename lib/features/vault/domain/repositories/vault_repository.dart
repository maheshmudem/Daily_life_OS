import '../entities/vault_item_entity.dart';

abstract class VaultRepository {
  Future<List<VaultPasswordEntity>> getPasswords();
  Future<List<VaultDocumentEntity>> getDocuments();
}
