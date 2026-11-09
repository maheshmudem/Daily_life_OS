import 'package:dartz/dartz.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDataSource _localDataSource;

  const ProfileRepositoryImpl(this._localDataSource);

  @override
  Future<Either<Failure, UserProfileEntity>> getProfile() =>
      guardRepositoryCall(() => _localDataSource.getProfile());

  @override
  Future<Either<Failure, UserProfileEntity>> saveProfile(
    UserProfileEntity profile,
  ) => guardRepositoryCall(() => _localDataSource.saveProfile(profile));

  @override
  Future<Either<Failure, String?>> pickAvatarImage({
    required bool fromCamera,
  }) => guardRepositoryCall(
    () => _localDataSource.pickAvatarImage(fromCamera: fromCamera),
  );
}
