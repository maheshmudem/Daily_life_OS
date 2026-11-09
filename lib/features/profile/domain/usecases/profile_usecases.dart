import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetUserProfileUseCase {
  final ProfileRepository _repository;

  const GetUserProfileUseCase(this._repository);

  Future<Either<Failure, UserProfileEntity>> call() => _repository.getProfile();
}

class SaveUserProfileUseCase {
  final ProfileRepository _repository;

  const SaveUserProfileUseCase(this._repository);

  Future<Either<Failure, UserProfileEntity>> call(UserProfileEntity profile) =>
      _repository.saveProfile(profile);
}

class PickProfileAvatarUseCase {
  final ProfileRepository _repository;

  const PickProfileAvatarUseCase(this._repository);

  Future<Either<Failure, String?>> call({required bool fromCamera}) =>
      _repository.pickAvatarImage(fromCamera: fromCamera);
}
