part of 'confirm_information_cubit.dart';

sealed class ConfirmInformationEffect {
  const ConfirmInformationEffect();
}

final class ConfirmInformationShowErrorEffect extends ConfirmInformationEffect {
  const ConfirmInformationShowErrorEffect({required this.error});

  final Object error;
}

final class ConfirmInformationInvalidOtpEffect
    extends ConfirmInformationEffect {
  const ConfirmInformationInvalidOtpEffect();
}

final class ConfirmInformationVerifiedEffect extends ConfirmInformationEffect {
  const ConfirmInformationVerifiedEffect();
}
