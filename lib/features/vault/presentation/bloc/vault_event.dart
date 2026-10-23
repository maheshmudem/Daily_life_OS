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

class UnlockVault extends VaultEvent {
  final bool isDecoy;

  const UnlockVault({required this.isDecoy});

  @override
  List<Object?> get props => [isDecoy];
}

class LockVault extends VaultEvent {
  const LockVault();
}
