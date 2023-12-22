part of 'home_page_cubit.dart';

class HomePageState extends BaseAppState with EquatableMixin {
  HomePageState({
    required LoadingStatus loading,
    dynamic error,
  }) : super(loading: loading, error: error);

  factory HomePageState.initial() {
    return HomePageState(
      loading: LoadingStatus.initial,
      error: null,
    );
  }

  HomePageState copyWith({LoadingStatus? loading, dynamic error}) {
    return HomePageState(
      loading: loading ?? this.loading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, error];
}
