part of 'confirm_information_cubit.dart';

class ConfirmInformationState extends BaseAppState {
  final bool isVerifying;
  final int counter;

  const ConfirmInformationState({
    required super.loading,
    super.error,
    this.isVerifying = false,
    this.counter = 0,
  });

  factory ConfirmInformationState.initial() {
    return ConfirmInformationState(loading: LoadingStatus.initial, error: null);
  }

  ConfirmInformationState copyWith({
    LoadingStatus? loading,
    Object? error,
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
  List<Object?> get props => [loading, error, isVerifying, counter];
}
