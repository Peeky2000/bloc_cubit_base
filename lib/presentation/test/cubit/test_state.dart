part of 'test_cubit.dart';

class TestState extends BaseAppState {
  const TestState({required super.loading, super.error});

  factory TestState.initial() {
    return TestState(loading: LoadingStatus.initial, error: null);
  }

  TestState copyWith({LoadingStatus? loading, Object? error}) {
    return TestState(loading: loading ?? this.loading, error: error);
  }

  @override
  List<Object?> get props => [loading, error];
}
