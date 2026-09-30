part of 'confirm_information_cubit.dart';

class ConfirmInformationState extends BaseAppState<Object> {
  const ConfirmInformationState({
    required super.loading,
    super.error,
    this.isVerifying = false,
    this.counter = 0,
    this.phone = '',
    this.effect,
  });

  final bool isVerifying;
  final int counter;
  final String phone;
  final UiEffect<ConfirmInformationEffect>? effect;

  factory ConfirmInformationState.initial() {
    return const ConfirmInformationState(loading: LoadingStatus.initial);
  }

  ConfirmInformationState copyWith({
    LoadingStatus? loading,
    Object? error,
    bool? isVerifying,
    int? counter,
    String? phone,
    UiEffect<ConfirmInformationEffect>? effect,
  }) {
    return ConfirmInformationState(
      loading: loading ?? this.loading,
      error: error,
      isVerifying: isVerifying ?? this.isVerifying,
      counter: counter ?? this.counter,
      phone: phone ?? this.phone,
      effect: effect ?? this.effect,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    error,
    isVerifying,
    counter,
    phone,
    effect,
  ];
}
