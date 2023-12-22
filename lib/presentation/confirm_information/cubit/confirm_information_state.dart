part of 'confirm_information_cubit.dart';

class ConfirmInformationState extends BaseAppState with EquatableMixin {
  bool isVerifying;
  int counter;

  ConfirmInformationState({
    required LoadingStatus loading,
    dynamic error,
    this.isVerifying = false,
    this.counter = 0,
  }) : super(loading: loading, error: error);

  factory ConfirmInformationState.initial() {
    return ConfirmInformationState(
      loading: LoadingStatus.initial,
      error: null,
    );
  }

  ConfirmInformationState copyWith({
    LoadingStatus? loading,
    dynamic error,
    bool? isVerifying,
    int? counter,
  }) {
    return ConfirmInformationState(
      loading: loading ?? this.loading,
      error: error,
      isVerifying: isVerifying ?? this.isVerifying,
      counter: counter ?? this.counter,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        error,
        isVerifying,
        counter,
      ];
}
