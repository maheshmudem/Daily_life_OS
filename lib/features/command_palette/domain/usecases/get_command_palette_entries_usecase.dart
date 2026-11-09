import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/command_palette_index.dart';
import '../repositories/command_palette_repository.dart';

class GetCommandPaletteEntriesUseCase
    implements UseCase<CommandPaletteIndex, NoParams> {
  final CommandPaletteRepository _repository;

  const GetCommandPaletteEntriesUseCase(this._repository);

  @override
  Future<Either<Failure, CommandPaletteIndex>> call(NoParams params) {
    return _repository.getIndex();
  }
}
