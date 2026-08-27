part of 'home_page_cubit.dart';

class HomePageState extends BaseAppState {
  const HomePageState({required super.loading, super.error});

  factory HomePageState.initial() {
    return HomePageState(loading: LoadingStatus.initial, error: null);
  }

  HomePageState copyWith({LoadingStatus? loading, Object? error}) {
    return HomePageState(loading: loading ?? this.loading, error: error);
  }

  @override
  List<Object?> get props => [loading, error];
}
