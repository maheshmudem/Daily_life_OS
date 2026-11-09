/// Lifecycle status shared by every feature BLoC state.
///
/// Using one enum (instead of a separate `Loading` / `Loaded` / `Error` class
/// per feature) keeps states as a single immutable `copyWith`-able object, so
/// previously loaded data stays visible while a refresh or retry runs.
enum BlocStatus {
  initial,
  loading,
  success,
  failure;

  bool get isInitial => this == BlocStatus.initial;
  bool get isLoading => this == BlocStatus.loading;
  bool get isSuccess => this == BlocStatus.success;
  bool get isFailure => this == BlocStatus.failure;

  /// `true` while there is nothing to show yet (first load in progress).
  bool get isBusy => isInitial || isLoading;
}
