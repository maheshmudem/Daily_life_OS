import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/bloc_status.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_command_palette_entries_usecase.dart';
import 'command_palette_event.dart';
import 'command_palette_state.dart';

export 'command_palette_event.dart';
export 'command_palette_state.dart';

class CommandPaletteBloc
    extends Bloc<CommandPaletteEvent, CommandPaletteState> {
  final GetCommandPaletteEntriesUseCase _getEntries;

  CommandPaletteBloc({
    required GetCommandPaletteEntriesUseCase getCommandPaletteEntriesUseCase,
  }) : _getEntries = getCommandPaletteEntriesUseCase,
       super(const CommandPaletteState()) {
    on<LoadCommandPalette>(_onLoad);
    on<UpdateCommandPaletteQuery>(_onUpdateQuery);
    on<SelectCommandPaletteModule>(_onSelectModule);
    on<ClearCommandPaletteQuery>(_onClearQuery);
  }

  Future<void> _onLoad(
    LoadCommandPalette event,
    Emitter<CommandPaletteState> emit,
  ) async {
    emit(state.copyWith(status: BlocStatus.loading, clearFailure: true));
    final result = await _getEntries(const NoParams());
    result.fold(
      (failure) =>
          emit(state.copyWith(status: BlocStatus.failure, failure: failure)),
      (index) => emit(
        state.copyWith(
          status: BlocStatus.success,
          allEntries: index.entries,
          failedModules: index.failedModules,
        ),
      ),
    );
  }

  void _onUpdateQuery(
    UpdateCommandPaletteQuery event,
    Emitter<CommandPaletteState> emit,
  ) {
    emit(state.copyWith(query: event.query));
  }

  void _onSelectModule(
    SelectCommandPaletteModule event,
    Emitter<CommandPaletteState> emit,
  ) {
    emit(state.copyWith(selectedModule: event.module));
  }

  void _onClearQuery(
    ClearCommandPaletteQuery event,
    Emitter<CommandPaletteState> emit,
  ) {
    emit(state.copyWith(query: ''));
  }
}
