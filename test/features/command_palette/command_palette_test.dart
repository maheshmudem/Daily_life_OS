import 'package:bloc_test/bloc_test.dart';
import 'package:daily_life_os/core/bloc/bloc_status.dart';
import 'package:daily_life_os/core/error/exceptions.dart';
import 'package:daily_life_os/core/error/failures.dart';
import 'package:daily_life_os/core/usecase/usecase.dart';
import 'package:daily_life_os/features/command_palette/data/datasources/command_palette_local_datasource.dart';
import 'package:daily_life_os/features/command_palette/data/models/command_palette_entry_model.dart';
import 'package:daily_life_os/features/command_palette/data/repositories/command_palette_repository_impl.dart';
import 'package:daily_life_os/features/command_palette/domain/entities/command_palette_entry_entity.dart';
import 'package:daily_life_os/features/command_palette/domain/entities/command_palette_index.dart';
import 'package:daily_life_os/features/command_palette/domain/usecases/get_command_palette_entries_usecase.dart';
import 'package:daily_life_os/features/command_palette/presentation/bloc/command_palette_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCommandPaletteLocalDataSource extends Mock
    implements CommandPaletteLocalDataSource {}

class MockGetCommandPaletteEntriesUseCase extends Mock
    implements GetCommandPaletteEntriesUseCase {}

CommandPaletteEntryModel entry(String id, String module, String title) {
  return CommandPaletteEntryModel(
    id: id,
    title: title,
    subtitle: '$module item',
    module: module,
    iconType: CommandPaletteIconType.bolt,
    accentColorValue: 0xFF000000,
    badgeText: module,
  );
}

void main() {
  group('CommandPaletteRepositoryImpl', () {
    late MockCommandPaletteLocalDataSource dataSource;
    late CommandPaletteRepositoryImpl repository;

    setUp(() {
      dataSource = MockCommandPaletteLocalDataSource();
      repository = CommandPaletteRepositoryImpl(dataSource);
      when(() => dataSource.getQuickCommands()).thenReturn([
        entry('cmd', CommandPaletteModules.actions, 'Quick Capture'),
      ]);
      when(() => dataSource.getTodayEntries()).thenAnswer(
        (_) async => [entry('h1', CommandPaletteModules.today, 'Drink water')],
      );
      when(() => dataSource.getPlannerEntries()).thenAnswer(
        (_) async => [entry('p1', CommandPaletteModules.planner, 'Standup')],
      );
      when(() => dataSource.getMoneyEntries()).thenAnswer((_) async => []);
      when(() => dataSource.getNotesEntries()).thenAnswer((_) async => []);
      when(() => dataSource.getVaultEntries()).thenAnswer((_) async => []);
    });

    test('merges quick commands with every module', () async {
      final result = await repository.getIndex();
      final index = result.getOrElse(() => throw StateError('expected Right'));

      expect(index.entries.map((e) => e.id), ['cmd', 'h1', 'p1']);
      expect(index.isPartial, isFalse);
    });

    test('a failing module is reported, the rest are still returned', () async {
      when(
        () => dataSource.getVaultEntries(),
      ).thenThrow(const CacheException(message: 'secure storage locked'));

      final result = await repository.getIndex();
      final index = result.getOrElse(() => throw StateError('expected Right'));

      expect(index.failedModules, [CommandPaletteModules.vault]);
      expect(index.entries.map((e) => e.id), ['cmd', 'h1', 'p1']);
    });
  });

  group('CommandPaletteBloc', () {
    late MockGetCommandPaletteEntriesUseCase getEntries;

    final index = CommandPaletteIndex(
      entries: [
        entry('cmd', CommandPaletteModules.actions, 'Start Focus (Pomodoro)'),
        entry('n1', CommandPaletteModules.notes, 'Grocery list'),
        entry('v1', CommandPaletteModules.vault, 'Bank login'),
      ],
    );

    setUpAll(() => registerFallbackValue(const NoParams()));
    setUp(() => getEntries = MockGetCommandPaletteEntriesUseCase());

    CommandPaletteBloc buildBloc() =>
        CommandPaletteBloc(getCommandPaletteEntriesUseCase: getEntries);

    blocTest<CommandPaletteBloc, CommandPaletteState>(
      'load success emits loading → success with entries',
      build: () {
        when(() => getEntries(any())).thenAnswer((_) async => Right(index));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadCommandPalette()),
      expect: () => [
        const CommandPaletteState(status: BlocStatus.loading),
        CommandPaletteState(
          status: BlocStatus.success,
          allEntries: index.entries,
        ),
      ],
    );

    blocTest<CommandPaletteBloc, CommandPaletteState>(
      'load failure emits failure state that can be retried',
      build: () {
        when(() => getEntries(any())).thenAnswer(
          (_) async => const Left(CacheFailure(message: 'db closed')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadCommandPalette()),
      expect: () => const [
        CommandPaletteState(status: BlocStatus.loading),
        CommandPaletteState(
          status: BlocStatus.failure,
          failure: CacheFailure(message: 'db closed'),
        ),
      ],
    );

    blocTest<CommandPaletteBloc, CommandPaletteState>(
      'query and module filters combine; clear resets the query',
      build: () {
        when(() => getEntries(any())).thenAnswer((_) async => Right(index));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const LoadCommandPalette());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const UpdateCommandPaletteQuery('pomodoro'));
      },
      verify: (bloc) {
        expect(bloc.state.filteredEntries.map((e) => e.id), ['cmd']);
        expect(bloc.state.moduleCounts[CommandPaletteModules.vault], 1);
      },
    );

    blocTest<CommandPaletteBloc, CommandPaletteState>(
      'selecting a module with no matches yields an empty result',
      build: () {
        when(() => getEntries(any())).thenAnswer((_) async => Right(index));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const LoadCommandPalette());
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(const UpdateCommandPaletteQuery('pomodoro'))
          ..add(const SelectCommandPaletteModule(CommandPaletteModules.vault));
      },
      verify: (bloc) => expect(bloc.state.filteredEntries, isEmpty),
    );
  });
}
