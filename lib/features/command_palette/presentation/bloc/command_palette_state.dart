import 'package:equatable/equatable.dart';

import '../../../../core/bloc/bloc_status.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/command_palette_entry_entity.dart';

class CommandPaletteState extends Equatable {
  final BlocStatus status;
  final List<CommandPaletteEntryEntity> allEntries;
  final List<String> failedModules;
  final String query;
  final String selectedModule;
  final Failure? failure;

  const CommandPaletteState({
    this.status = BlocStatus.initial,
    this.allEntries = const [],
    this.failedModules = const [],
    this.query = '',
    this.selectedModule = CommandPaletteModules.all,
    this.failure,
  });

  bool get isPartial => failedModules.isNotEmpty;

  Map<String, int> get moduleCounts {
    final counts = <String, int>{CommandPaletteModules.all: allEntries.length};
    for (final mod in CommandPaletteModules.ordered.skip(1)) {
      counts[mod] = allEntries.where((e) => e.module == mod).length;
    }
    return counts;
  }

  List<CommandPaletteEntryEntity> get filteredEntries {
    final normalizedQuery = query.trim().toLowerCase();
    return allEntries.where((entry) {
      final matchesModule =
          selectedModule == CommandPaletteModules.all ||
          entry.module == selectedModule;
      return matchesModule && entry.matchesQuery(normalizedQuery);
    }).toList();
  }

  CommandPaletteState copyWith({
    BlocStatus? status,
    List<CommandPaletteEntryEntity>? allEntries,
    List<String>? failedModules,
    String? query,
    String? selectedModule,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return CommandPaletteState(
      status: status ?? this.status,
      allEntries: allEntries ?? this.allEntries,
      failedModules: failedModules ?? this.failedModules,
      query: query ?? this.query,
      selectedModule: selectedModule ?? this.selectedModule,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    allEntries,
    failedModules,
    query,
    selectedModule,
    failure,
  ];
}
