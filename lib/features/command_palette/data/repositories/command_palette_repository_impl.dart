import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/command_palette_entry_entity.dart';
import '../../domain/entities/command_palette_index.dart';
import '../../domain/repositories/command_palette_repository.dart';
import '../datasources/command_palette_local_datasource.dart';
import '../models/command_palette_entry_model.dart';

class CommandPaletteRepositoryImpl implements CommandPaletteRepository {
  final CommandPaletteLocalDataSource _localDataSource;

  const CommandPaletteRepositoryImpl(this._localDataSource);

  @override
  Future<Either<Failure, CommandPaletteIndex>> getIndex() {
    return guardRepositoryCall(context: 'CommandPalette.getIndex', () async {
      final loaders =
          <String, Future<List<CommandPaletteEntryModel>> Function()>{
            CommandPaletteModules.today: _localDataSource.getTodayEntries,
            CommandPaletteModules.planner: _localDataSource.getPlannerEntries,
            CommandPaletteModules.money: _localDataSource.getMoneyEntries,
            CommandPaletteModules.notes: _localDataSource.getNotesEntries,
            CommandPaletteModules.vault: _localDataSource.getVaultEntries,
          };

      // Load all modules in parallel; one failing module must not hide the
      // others, so each failure is captured and reported instead of thrown.
      // Loaders are invoked *inside* the try so synchronous throws are caught.
      final failedModules = <String>[];
      final moduleResults = await Future.wait(
        loaders.entries.map((entry) async {
          try {
            return await entry.value();
          } catch (error, stackTrace) {
            failedModules.add(entry.key);
            developer.log(
              'Command palette module "${entry.key}" failed to index',
              name: 'DailyLifeOS.CommandPalette',
              error: error,
              stackTrace: stackTrace,
            );
            return const <CommandPaletteEntryModel>[];
          }
        }),
      );

      return CommandPaletteIndex(
        entries: [
          ..._localDataSource.getQuickCommands(),
          for (final list in moduleResults) ...list,
        ],
        failedModules: List.unmodifiable(failedModules),
      );
    });
  }
}
