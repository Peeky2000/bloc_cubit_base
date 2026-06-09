part of 'test_cubit.dart';

class TestState extends BaseAppState with EquatableMixin {
  TestState({
    required LoadingStatus loading,
    dynamic error,
  }) : super(loading: loading, error: error);

  factory TestState.initial() {
    return TestState(
      loading: LoadingStatus.initial,
      error: null,
    );
  }

  TestState copyWith({LoadingStatus? loading, dynamic error}) {
    return TestState(
      loading: loading ?? this.loading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, error];
}

