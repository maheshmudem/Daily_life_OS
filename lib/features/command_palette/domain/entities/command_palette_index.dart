import 'package:equatable/equatable.dart';

import 'command_palette_entry_entity.dart';

/// Result of indexing every module for the Command Palette.
///
/// Indexing is resilient: if one module (e.g. Vault) fails to load, the other
/// modules are still returned and the failed module names are reported in
/// [failedModules] so the UI can tell the user instead of hiding it.
class CommandPaletteIndex extends Equatable {
  final List<CommandPaletteEntryEntity> entries;
  final List<String> failedModules;

  const CommandPaletteIndex({
    required this.entries,
    this.failedModules = const [],
  });

  bool get isPartial => failedModules.isNotEmpty;

  @override
  List<Object?> get props => [entries, failedModules];
}
