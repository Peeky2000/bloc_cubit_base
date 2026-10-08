import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/core/validation/auth_validation_error.dart';
import 'package:bloc_cubit_base/domain/entities/auth/sign_up_params.dart';
import 'package:bloc_cubit_base/domain/entities/common/app_enums.dart';
import 'package:bloc_cubit_base/domain/repositories/phone_verification_repo.dart';
import 'package:bloc_cubit_base/domain/use_case/auth_use_case.dart';
import 'package:bloc_cubit_base/presentation/sign_up/cubit/sign_up_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

const _phone = '0912345678';
const _normalizedPhone = '+84912345678';
const _email = 'shop@example.com';
const _password = 'Password@1';

void main() {
  late _MockAuthUseCase authUseCase;
  late SignUpCubit cubit;

  setUpAll(() {
    registerFallbackValue(
      const SignUpParams(
        email: '',
        password: '',
        phone: '',
        industry: '',
        shippingScale: ScaleLevel.KHONG_THUONG_XUYEN,
        shopName: '',
      ),
    );
  });

  setUp(() {
    authUseCase = _MockAuthUseCase();
    cubit = SignUpCubit(authUseCase);
  });

  tearDown(() async {
    if (!cubit.isClosed) {
      await cubit.close();
    }
  });

  void stubSignUp() => when(
    () => authUseCase.userSignUp(request: any(named: 'request')),
  ).thenAnswer((_) async => null);

  void stubSend(Future<PhoneVerificationOutcome> Function() answer) => when(
    () => authUseCase.sendCodeVerify(phone: any(named: 'phone')),
  ).thenAnswer((_) => answer());

  void fillAccountPage() =>
      cubit.onTapSignUp(phone: _phone, email: _email, pass: _password);

  void fillShopPage() {
    cubit.onChangeSelectedIndustry(IndustryType.THOI_TRANG, 'fashion', true);
    cubit.onChangeScaleLevel(ScaleLevel.DUOI_150_THANG);
  }

  group('account page', () {
    test('empty input reports required errors and stays on the form', () {
      cubit.onTapSignUp(phone: '', email: '', pass: '');

      expect(cubit.state.phoneError, PhoneInputError.required);
      expect(cubit.state.emailError, EmailInputError.required);
      expect(cubit.state.passwordError, PasswordInputError.required);
      expect(cubit.state.effect, isNull);
    });

    test('malformed input reports invalid errors and stays on the form', () {
      cubit.onTapSignUp(phone: '12345', email: 'not-an-email', pass: 'weak');

      expect(cubit.state.phoneError, PhoneInputError.invalid);
      expect(cubit.state.emailError, EmailInputError.invalid);
      expect(cubit.state.passwordError, PasswordInputError.invalid);
      expect(cubit.state.effect, isNull);
    });

    test('valid input clears earlier errors and advances one page', () {
      cubit.onTapSignUp(phone: '', email: '', pass: '');

      fillAccountPage();

      expect(cubit.state.phoneError, isNull);
      expect(cubit.state.emailError, isNull);
      expect(cubit.state.passwordError, isNull);
      final effect = cubit.state.effect?.value;
      expect(effect, isA<SignUpChangePageEffect>());
      expect((effect! as SignUpChangePageEffect).delta, 1);
    });

    test('going back publishes a backward page change', () {
      cubit.previousPage();

      final effect = cubit.state.effect?.value as SignUpChangePageEffect;
      expect(effect.delta, -1);
    });
  });

  group('shop page', () {
    test(
      'missing shop details report required errors without signing up',
      () async {
        fillAccountPage();

        await cubit.onTapConfirmInfo(shopName: '');

        expect(cubit.state.shopNameError, RequiredInputError.required);
        expect(cubit.state.industryError, RequiredInputError.required);
        expect(cubit.state.scaleError, RequiredInputError.required);
        verifyNever(
          () => authUseCase.userSignUp(request: any(named: 'request')),
        );
      },
    );

    test('a deselected industry is dropped from the selection', () {
      cubit.onChangeSelectedIndustry(IndustryType.THOI_TRANG, 'fashion', true);
      cubit.onChangeSelectedIndustry(IndustryType.MY_PHAM, 'beauty', true);
      cubit.onChangeSelectedIndustry(IndustryType.THOI_TRANG, 'fashion', false);

      expect(cubit.state.industries, [IndustryType.MY_PHAM]);
    });
  });

  group('submission', () {
    test(
      'signs up with the normalized phone, sends a code, then asks for it',
      () async {
        stubSignUp();
        stubSend(() async => PhoneVerificationOutcome.codeSent);
        fillAccountPage();
        cubit.onChangeSelectedIndustry(
          IndustryType.THOI_TRANG,
          'fashion',
          true,
        );
        cubit.onChangeSelectedIndustry(IndustryType.MY_PHAM, 'beauty', true);
        cubit.onChangeScaleLevel(ScaleLevel.DUOI_150_THANG);

        await cubit.onTapConfirmInfo(shopName: 'My Shop');

        verify(
          () => authUseCase.userSignUp(
            request: const SignUpParams(
              email: _email,
              password: _password,
              phone: _normalizedPhone,
              industry: 'fashion,beauty',
              shippingScale: ScaleLevel.DUOI_150_THANG,
              shopName: 'My Shop',
            ),
          ),
        ).called(1);
        verify(
          () => authUseCase.sendCodeVerify(phone: _normalizedPhone),
        ).called(1);
        expect(cubit.state.loading, LoadingStatus.complete);
        final effect = cubit.state.effect?.value;
        expect(effect, isA<SignUpNavigatePhoneVerificationEffect>());
        expect(
          (effect! as SignUpNavigatePhoneVerificationEffect).phone,
          _normalizedPhone,
        );
      },
    );

    test('a sign-up failure offers to retry the sign-up', () async {
      final error = StateError('sign-up failed');
      when(
        () => authUseCase.userSignUp(request: any(named: 'request')),
      ).thenThrow(error);
      fillAccountPage();
      fillShopPage();

      await cubit.onTapConfirmInfo(shopName: 'My Shop');

      expect(cubit.state.loading, LoadingStatus.error);
      final effect = cubit.state.effect?.value as SignUpShowErrorEffect;
      expect(effect.error, same(error));
      expect(effect.retryAction, SignUpRetryAction.signUp);
      verifyNever(() => authUseCase.sendCodeVerify(phone: any(named: 'phone')));
    });

    test('a send-code failure offers to retry sending the code', () async {
      const error = PhoneVerificationFailure('quota-exceeded');
      stubSignUp();
      when(
        () => authUseCase.sendCodeVerify(phone: any(named: 'phone')),
      ).thenThrow(error);
      fillAccountPage();
      fillShopPage();

      await cubit.onTapConfirmInfo(shopName: 'My Shop');

      final effect = cubit.state.effect?.value as SignUpShowErrorEffect;
      expect(effect.error, same(error));
      expect(effect.retryAction, SignUpRetryAction.sendVerificationCode);
    });

    test('retrying the code resends to the signed-up phone', () async {
      stubSignUp();
      when(
        () => authUseCase.sendCodeVerify(phone: any(named: 'phone')),
      ).thenThrow(const PhoneVerificationFailure('network-request-failed'));
      fillAccountPage();
      fillShopPage();
      await cubit.onTapConfirmInfo(shopName: 'My Shop');

      stubSend(() async => PhoneVerificationOutcome.codeSent);
      await cubit.sendCodeVerify();

      expect(
        cubit.state.effect?.value,
        isA<SignUpNavigatePhoneVerificationEffect>(),
      );
      verify(
        () => authUseCase.userSignUp(request: any(named: 'request')),
      ).called(1);
      verify(
        () => authUseCase.sendCodeVerify(phone: _normalizedPhone),
      ).called(2);
    });

    test('a superseded send-code request does nothing', () async {
      stubSignUp();
      stubSend(() async => PhoneVerificationOutcome.superseded);
      fillAccountPage();
      fillShopPage();
      final pageEffect = cubit.state.effect;

      await cubit.onTapConfirmInfo(shopName: 'My Shop');

      expect(cubit.state.effect, same(pageEffect));
    });
  });
}

class _MockAuthUseCase extends Mock implements AuthUseCase {}
