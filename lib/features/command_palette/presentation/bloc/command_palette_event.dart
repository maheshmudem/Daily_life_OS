import 'package:equatable/equatable.dart';

abstract class CommandPaletteEvent extends Equatable {
  const CommandPaletteEvent();

  @override
  List<Object?> get props => [];
}

/// Builds (or rebuilds, on retry) the search index.
class LoadCommandPalette extends CommandPaletteEvent {
  const LoadCommandPalette();
}

class UpdateCommandPaletteQuery extends CommandPaletteEvent {
  final String query;

  const UpdateCommandPaletteQuery(this.query);

  @override
  List<Object?> get props => [query];
}

class SelectCommandPaletteModule extends CommandPaletteEvent {
  final String module;

  const SelectCommandPaletteModule(this.module);

  @override
  List<Object?> get props => [module];
}

class ClearCommandPaletteQuery extends CommandPaletteEvent {
  const ClearCommandPaletteQuery();
}
