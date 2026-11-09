import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/command_palette_index.dart';

abstract class CommandPaletteRepository {
  /// Builds the searchable index across all modules.
  Future<Either<Failure, CommandPaletteIndex>> getIndex();
}
