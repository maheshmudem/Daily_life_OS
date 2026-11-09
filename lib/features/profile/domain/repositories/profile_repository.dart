import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_profile_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserProfileEntity>> getProfile();
  Future<Either<Failure, UserProfileEntity>> saveProfile(
    UserProfileEntity profile,
  );
  Future<Either<Failure, String?>> pickAvatarImage({required bool fromCamera});
}
