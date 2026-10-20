import 'package:equatable/equatable.dart';

abstract class VaultEvent extends Equatable {
  const VaultEvent();

  @override
  List<Object?> get props => [];
}

class LoadVault extends VaultEvent {
  const LoadVault();
}

class ToggleDecoyMode extends VaultEvent {
  const ToggleDecoyMode();
}
