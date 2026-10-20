import 'package:equatable/equatable.dart';
import '../../domain/entities/vault_item_entity.dart';

abstract class VaultState extends Equatable {
  const VaultState();

  @override
  List<Object?> get props => [];
}

class VaultInitial extends VaultState {}

class VaultLoading extends VaultState {}

class VaultLoaded extends VaultState {
  final List<VaultPasswordEntity> passwords;
  final List<VaultDocumentEntity> documents;
  final bool isDecoyMode;

  const VaultLoaded({
    required this.passwords,
    required this.documents,
    this.isDecoyMode = false,
  });

  @override
  List<Object?> get props => [passwords, documents, isDecoyMode];
}

class VaultError extends VaultState {
  final String message;

  const VaultError(this.message);

  @override
  List<Object?> get props => [message];
}
