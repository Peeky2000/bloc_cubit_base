import 'package:bloc_cubit_base/core/app/app.dart';
import 'package:bloc_cubit_base/core/common/route.dart';
import 'package:bloc_cubit_base/domain/entities/common/app_enums.dart';
import 'package:bloc_cubit_base/core/extension/list_extension.dart';
import 'package:bloc_cubit_base/core/routing/routing.dart';
import 'package:bloc_cubit_base/core/validation/auth_validation_error.dart';
import 'package:bloc_cubit_base/generated/assets.gen.dart';
import 'package:bloc_cubit_base/l10n/l10n.dart';
import 'package:bloc_cubit_base/widget/app_primary_button.dart';
import 'package:bloc_cubit_base/widget/loading_screen.dart';
import 'package:bloc_cubit_base/widget/selection_bottom_sheet.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_cubit_base/core/mixin/after_layout.dart';
import 'package:bloc_cubit_base/di/injection.dart';
import 'package:bloc_cubit_base/presentation/sign_up/cubit/sign_up_cubit.dart';
import 'package:bloc_cubit_base/presentation/global_handler.dart';
import 'package:bloc_cubit_base/core/widget/common_text_field.dart';
import 'package:bloc_cubit_base/core/widget/common_drop_down.dart';

Widget signUpScreenBuilder() => BlocProvider<SignUpCubit>(
  create: (_) => getIt<SignUpCubit>(),
  child: const SignUpScreen(),
);

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with AfterLayoutMixin {
  SignUpCubit? _signUpCubit;
  final PageController _pageController = PageController();
  final TextEditingController _phoneEditingController = TextEditingController();
  final TextEditingController _emailEditingController = TextEditingController();
  final TextEditingController _passEditingController = TextEditingController();
  final TextEditingController _shopNameEditingController =
      TextEditingController();
  List<SelectionItemModel<ScaleLevel>> itemsScaleLevel = [];
  List<SelectionItemModel<IndustryType>> itemsIndustry = [];

  @override
  void initState() {
    super.initState();
    _signUpCubit = context.read<SignUpCubit>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    itemsScaleLevel = [
      SelectionItemModel(
        value: ScaleLevel.KHONG_THUONG_XUYEN,
        title: context.l10n.scaleL1,
      ),
      SelectionItemModel(
        value: ScaleLevel.DUOI_150_THANG,
        title: context.l10n.scaleL2,
      ),
      SelectionItemModel(
        value: ScaleLevel.DUOI_900_THANG,
        title: context.l10n.scaleL3,
      ),
      SelectionItemModel(
        value: ScaleLevel.DUOI_3000_THANG,
        title: context.l10n.scaleL4,
      ),
      SelectionItemModel(
        value: ScaleLevel.DUOI_6000_THANG,
        title: context.l10n.scaleL5,
      ),
      SelectionItemModel(
        value: ScaleLevel.TREN_6000_THANG,
        title: context.l10n.scaleL6,
      ),
    ];
    itemsIndustry = [
      SelectionItemModel(
        value: IndustryType.THOI_TRANG,
        title: context.l10n.fashion,
      ),
      SelectionItemModel(
        value: IndustryType.MY_PHAM,
        title: context.l10n.cosmetics,
      ),
      SelectionItemModel(
        value: IndustryType.NOI_THAT,
        title: context.l10n.industry,
      ),
      SelectionItemModel(
        value: IndustryType.ME_VA_BE,
        title: context.l10n.motherAndBaby,
      ),
      SelectionItemModel(
        value: IndustryType.MAY_TINH,
        title: context.l10n.computers,
      ),
      SelectionItemModel(
        value: IndustryType.HANG_HOA_DE_VO,
        title: context.l10n.fragileGoods,
      ),
      SelectionItemModel(
        value: IndustryType.TIVI_VA_THIET_BI_GIA_DUNG,
        title: context.l10n.householdElectrical,
      ),
      SelectionItemModel(
        value: IndustryType.GIA_DUNG,
        title: context.l10n.houseware,
      ),
      SelectionItemModel(
        value: IndustryType.XE_MAY_VA_PHUONG_TIEN,
        title: context.l10n.motorcycles,
      ),
      SelectionItemModel(
        value: IndustryType.CAY_TRONG_VA_NONG_NGHIEP,
        title: context.l10n.drums,
      ),
      SelectionItemModel(
        value: IndustryType.THUC_PHAM_VA_NONG_SAN,
        title: context.l10n.food,
      ),
      SelectionItemModel(
        value: IndustryType.DUNG_CU_VA_PHU_KIEN,
        title: context.l10n.sports,
      ),
      SelectionItemModel(
        value: IndustryType.TRANG_SUC_VA_PHU_KIEN,
        title: context.l10n.jewelry,
      ),
      SelectionItemModel(
        value: IndustryType.HANG_TIEU_DUNG,
        title: context.l10n.consumables,
      ),
      SelectionItemModel(
        value: IndustryType.SACH_VA_VAN_PHONG_PHAM,
        title: context.l10n.books,
      ),
      SelectionItemModel(value: IndustryType.KHAC, title: context.l10n.other),
    ];
  }

  @override
  void afterFirstLayout(BuildContext context) {}

  @override
  void dispose() {
    _pageController.dispose();
    _phoneEditingController.dispose();
    _emailEditingController.dispose();
    _passEditingController.dispose();
    _shopNameEditingController.dispose();
    super.dispose();
  }

  void animateToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeIn,
    );
  }

  Widget _buildSignUpPage() {
    return Padding(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.signUp.toUpperCase(),
            style: App.appStyle?.bold24?.copyWith(
              color: App.appColor?.textColorPrimary,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 16.h, bottom: 32.h),
            child: Text(
              context.l10n.welcomeTitle,
              style: App.appStyle?.medium14?.copyWith(
                color: App.appColor?.textColor,
              ),
            ),
          ),
          BlocBuilder<SignUpCubit, SignUpState>(
            builder: (context, state) {
              return CommonTextField(
                controller: _phoneEditingController,
                title: context.l10n.phoneNumber,
                hint: context.l10n.phoneNumber,
                keyboardType: TextInputType.phone,
                error: _phoneError(context, state.phoneError),
              );
            },
          ),
          SizedBox(height: 16.h),
          BlocBuilder<SignUpCubit, SignUpState>(
            builder: (context, state) {
              return CommonTextField(
                controller: _emailEditingController,
                title: context.l10n.email,
                hint: context.l10n.email,
                keyboardType: TextInputType.emailAddress,
                error: _emailError(context, state.emailError),
              );
            },
          ),
          SizedBox(height: 16.h),
          BlocBuilder<SignUpCubit, SignUpState>(
            builder: (context, state) {
              return CommonTextField(
                controller: _passEditingController,
                title: context.l10n.password,
                hint: context.l10n.password,
                keyboardType: TextInputType.visiblePassword,
                error: _passwordError(context, state.passwordError),
                obscureText: !(_signUpCubit?.state.showPass ?? false),
                suffixConstraints: BoxConstraints.tightFor(
                  width: 44.w,
                  height: 20.w,
                ),
                suffix: GestureDetector(
                  onTap: () => _signUpCubit?.onChangeShowPass(),
                  child: Icon(
                    state.showPass == true
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: App.appColor?.iconColor,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 32.h),
          AppPrimaryButton(
            title: context.l10n.signUpNowPerWord,
            onTap: () {
              String phone = _phoneEditingController.text.trim();
              String email = _emailEditingController.text.trim();
              String pass = _passEditingController.text.trim();
              _signUpCubit?.onTapSignUp(phone: phone, email: email, pass: pass);
            },
          ),
          SizedBox(height: 32.h),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${context.l10n.alreadyAcc} ',
                  style: App.appStyle?.medium14?.copyWith(
                    color: App.appColor?.textColor,
                  ),
                ),
                TextSpan(
                  text: context.l10n.signInNow,
                  style: App.appStyle?.medium14?.copyWith(
                    color: App.appColor?.textColorPrimary,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      SLIRouting.offAllNamed(AppPage.signIn);
                    },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSelectionScale() {
    int index = itemsScaleLevel.indexWhere(
      (element) => element.value == _signUpCubit?.state.currentScaleLevel,
    );
    SLIRouting.bottomSheet(
      SelectionBottomSheet(
        title: context.l10n.shippingScale,
        data: itemsScaleLevel,
        indexSelected: index >= 0 ? index : null,
        isIntrinsicHeight: false,
        height: MediaQuery.of(context).size.height * 1.5 / 3.0,
        onSelected: (index) =>
            _signUpCubit?.onChangeScaleLevel(itemsScaleLevel[index].value),
      ),
      isScrollControlled: true,
    );
  }

  void _showSelectionIndustry() {
    final List<int> listIndex = [];
    for (IndustryType type in _signUpCubit?.state.industries ?? []) {
      int index = itemsIndustry.indexWhere((element) => element.value == type);
      if (index >= 0) {
        listIndex.add(index);
      }
    }
    SLIRouting.bottomSheet(
      MultiSelectionBottomSheet(
        title: context.l10n.industry,
        data: itemsIndustry,
        isIntrinsicHeight: true,
        onSelected: (index, selected) => _signUpCubit?.onChangeSelectedIndustry(
          itemsIndustry[index].value,
          itemsIndustry[index].title,
          selected,
        ),
        indexSelected: listIndex,
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildInfoShop() {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(32.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                context.l10n.shopInfo.toUpperCase(),
                style: App.appStyle?.bold24?.copyWith(
                  color: App.appColor?.textColorPrimary,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 16.h, bottom: 32.h),
                child: Text(
                  context.l10n.brandTagline,
                  style: App.appStyle?.medium14?.copyWith(
                    color: App.appColor?.textColor,
                  ),
                ),
              ),
              BlocBuilder<SignUpCubit, SignUpState>(
                builder: (context, state) {
                  return CommonTextField(
                    controller: _shopNameEditingController,
                    title: context.l10n.shopName,
                    hint: context.l10n.shopName,
                    keyboardType: TextInputType.name,
                    error: state.shopNameError == null
                        ? null
                        : context.l10n.shopNameIsRequired,
                  );
                },
              ),
              SizedBox(height: 16.h),
              BlocBuilder<SignUpCubit, SignUpState>(
                builder: (context, state) {
                  List<String> names = [];
                  for (IndustryType type in state.industries ?? []) {
                    String? title = itemsIndustry
                        .firstWhereOrNull((element) => element.value == type)
                        ?.title;
                    if (title != null) {
                      names.add(title);
                    }
                  }
                  return CommonDropDown(
                    title: context.l10n.industry,
                    hint: context.l10n.industry,
                    value: names.join(', '),
                    onTap: () => _showSelectionIndustry(),
                    maxLine: 2,
                    error: state.industryError == null
                        ? null
                        : context.l10n.industryIsRequired,
                  );
                },
              ),
              SizedBox(height: 16.h),
              BlocBuilder<SignUpCubit, SignUpState>(
                builder: (context, state) {
                  String? title = itemsScaleLevel
                      .firstWhereOrNull(
                        (item) => item.value == state.currentScaleLevel,
                      )
                      ?.title;
                  return CommonDropDown(
                    title: context.l10n.shippingScale,
                    hint: context.l10n.shippingScale,
                    onTap: () => _showSelectionScale(),
                    value: title,
                    error: state.scaleError == null
                        ? null
                        : context.l10n.scaleLevelIsRequired,
                  );
                },
              ),
              SizedBox(height: 32.h),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${context.l10n.tos1} '),
                    TextSpan(
                      text: context.l10n.tos2,
                      style: App.appStyle?.bold14?.copyWith(
                        color: App.appColor?.textColor,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = () {},
                    ),
                    TextSpan(text: ' ${context.l10n.and} '),
                    TextSpan(
                      text: context.l10n.tos3,
                      style: App.appStyle?.bold14?.copyWith(
                        color: App.appColor?.textColor,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = () {},
                    ),
                    TextSpan(text: ' ${context.l10n.tos4}'),
                  ],
                ),
                style: App.appStyle?.regular14?.copyWith(
                  color: App.appColor?.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              AppPrimaryButton(
                title: context.l10n.confirmInfo,
                onTap: () {
                  String shopName = _shopNameEditingController.text.trim();
                  _signUpCubit?.onTapConfirmInfo(shopName: shopName);
                },
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.only(top: 24.h, left: 12.w),
            child: BackButton(onPressed: () => _signUpCubit?.previousPage()),
          ),
        ),
      ],
    );
  }

  double pageViewHeight(int index) {
    double height = MediaQuery.of(context).size.height;
    double imageHeight = MediaQuery.of(context).size.width * 320.0.h / 430.0.w;
    if (index == 1) {
      return height - imageHeight + 20.h;
    }
    return height - imageHeight + 20.h;
  }

  @override
  Widget build(BuildContext context) {
    return LoadingScreen<SignUpCubit, SignUpState>(
      listenWhen: (previous, current) => previous.effect != current.effect,
      listener: (context, state) {
        final effect = state.effect?.value;
        switch (effect) {
          case SignUpChangePageEffect(:final delta):
            animateToPage(state.currentPage + delta);
          case SignUpNavigatePhoneVerificationEffect(:final phone):
            SLIRouting.toNamed(
              AppPage.confirmInfo,
              arguments: {'phone': phone, 'page_success': AppPage.signIn},
            );
          case SignUpShowErrorEffect(:final error, :final retryAction):
            handleErrorResponse(
              context,
              error,
              onRetry: () => switch (retryAction) {
                SignUpRetryAction.signUp => _signUpCubit!.onTapConfirmInfo(
                  shopName: _shopNameEditingController.text.trim(),
                ),
                SignUpRetryAction.sendVerificationCode =>
                  _signUpCubit!.sendCodeVerify(),
              },
            );
          case null:
            break;
        }
      },
      builder: (context, state) => Scaffold(
        body: ListView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            AspectRatio(
              aspectRatio: 430.0.w / 320.0.h,
              child: Assets.images.imgAds.image(fit: BoxFit.cover),
            ),
            BlocBuilder<SignUpCubit, SignUpState>(
              builder: (context, state) {
                return SafeArea(
                  top: false,
                  child: SizedBox(
                    height: pageViewHeight(state.currentPage),
                    child: PageView(
                      physics: const NeverScrollableScrollPhysics(),
                      controller: _pageController,
                      onPageChanged: (index) => _signUpCubit?.changePage(index),
                      children: [_buildSignUpPage(), _buildInfoShop()],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String? _phoneError(BuildContext context, PhoneInputError? error) =>
      switch (error) {
        PhoneInputError.required => context.l10n.phoneIsRequired,
        PhoneInputError.invalid => context.l10n.phoneIsInvalid,
        null => null,
      };

  String? _emailError(BuildContext context, EmailInputError? error) =>
      switch (error) {
        EmailInputError.required => context.l10n.emailIsRequired,
        EmailInputError.invalid => context.l10n.emailIsInvalid,
        null => null,
      };

  String? _passwordError(BuildContext context, PasswordInputError? error) =>
      switch (error) {
        PasswordInputError.required => context.l10n.passIsRequired,
        PasswordInputError.invalid => context.l10n.passIsInvalid,
        PasswordInputError.mismatch => context.l10n.confirmPassIsNotMath,
        null => null,
      };
}
