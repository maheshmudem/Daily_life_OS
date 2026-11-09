import 'package:equatable/equatable.dart';
import '../../../../core/bloc/bloc_status.dart';
import '../../domain/entities/user_profile_entity.dart';

class ProfileState extends Equatable {
  final BlocStatus status;
  final UserProfileEntity profile;
  final String? errorMessage;

  const ProfileState({
    this.status = BlocStatus.initial,
    this.profile = const UserProfileEntity(),
    this.errorMessage,
  });

  ProfileState copyWith({
    BlocStatus? status,
    UserProfileEntity? profile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
}
