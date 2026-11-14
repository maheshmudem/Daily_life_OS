import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/monitoring/app_monitor.dart';
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
    on<UnlockVault>(_onUnlock);
    on<LockVault>(_onLock);
  }

  Future<void> _onLoad(LoadVault event, Emitter<VaultState> emit) async {
    final prevUnlocked = state is VaultLoaded
        ? (state as VaultLoaded).isUnlocked
        : false;
    final prevDecoy = state is VaultLoaded
        ? (state as VaultLoaded).isDecoyMode
        : false;
    if (state is! VaultLoaded) {
      emit(VaultLoading());
    }
    try {
      final passwordsFuture = getVaultPasswordsUseCase();
      final documentsFuture = getVaultDocumentsUseCase();
      await Future.wait([passwordsFuture, documentsFuture]);
      final passwords = await passwordsFuture;
      final documents = await documentsFuture;
      emit(
        VaultLoaded(
          passwords: passwords,
          documents: documents,
          isUnlocked: prevUnlocked,
          isDecoyMode: prevDecoy,
        ),
      );
    } catch (e, st) {
      AppMonitor.instance.recordError(
        e,
        st,
        source: 'vault.load',
        fallbackAction: 'open your vault items',
      );
      emit(
        VaultError(
          AppMonitor.friendlyMessage(
            e,
            fallbackAction: 'open your vault items',
          ),
        ),
      );
    }
  }

  void _onToggleDecoy(ToggleDecoyMode event, Emitter<VaultState> emit) {
    final current = state;
    if (current is VaultLoaded) {
      emit(current.copyWith(isDecoyMode: !current.isDecoyMode));
    }
  }

  void _onUnlock(UnlockVault event, Emitter<VaultState> emit) {
    final current = state;
    if (current is VaultLoaded) {
      emit(current.copyWith(isUnlocked: true, isDecoyMode: event.isDecoy));
    }
  }

  void _onLock(LockVault event, Emitter<VaultState> emit) {
    final current = state;
    if (current is VaultLoaded) {
      emit(current.copyWith(isUnlocked: false));
    }
  }
}
