import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_vault_items_usecase.dart';
import 'vault_event.dart';
import 'vault_state.dart';

export 'vault_event.dart';
export 'vault_state.dart';

class VaultBloc extends Bloc<VaultEvent, VaultState> {
  final GetVaultPasswordsUseCase getVaultPasswordsUseCase;
  final GetVaultDocumentsUseCase getVaultDocumentsUseCase;

  VaultBloc({
    required this.getVaultPasswordsUseCase,
    required this.getVaultDocumentsUseCase,
  }) : super(VaultInitial()) {
    on<LoadVault>(_onLoad);
    on<ToggleDecoyMode>(_onToggleDecoy);
  }

  Future<void> _onLoad(LoadVault event, Emitter<VaultState> emit) async {
    emit(VaultLoading());
    try {
      final passwords = await getVaultPasswordsUseCase();
      final documents = await getVaultDocumentsUseCase();
      emit(VaultLoaded(passwords: passwords, documents: documents));
    } catch (e) {
      emit(VaultError(e.toString()));
    }
  }

  void _onToggleDecoy(ToggleDecoyMode event, Emitter<VaultState> emit) {
    final current = state;
    if (current is VaultLoaded) {
      emit(VaultLoaded(
        passwords: current.passwords,
        documents: current.documents,
        isDecoyMode: !current.isDecoyMode,
      ));
    }
  }
}
