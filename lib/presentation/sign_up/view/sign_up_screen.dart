import 'package:delivery_go/core/app/app.dart';
import 'package:delivery_go/core/app/app_controller.dart';
import 'package:delivery_go/core/common/enum.dart';
import 'package:delivery_go/core/common/route.dart';
import 'package:delivery_go/core/extension/list_extension.dart';
import 'package:delivery_go/core/routing/routing.dart';
import 'package:delivery_go/generated/assets.gen.dart';
import 'package:delivery_go/l10n/l10n.dart';
import 'package:delivery_go/widget/delivery_go_button.dart';
import 'package:delivery_go/widget/loading_screen.dart';
import 'package:delivery_go/widget/selection_bottom_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sli_common/sli_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:delivery_go/core/mixin/after_layout.dart';
import 'package:delivery_go/di/injection.dart';
import 'package:delivery_go/presentation/sign_up/cubit/sign_up_cubit.dart';

Widget signUpScreenBuilder() => BlocProvider<SignUpCubit>(
      create: (_) => Injector.getIt.get<SignUpCubit>(),
      child: const SignUpScreen(),
    );

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
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

  BuildContext? appContext = Injector.getIt.get<AppController>().context;

  @override
  void initState() {
    super.initState();
    _signUpCubit = context.read<SignUpCubit>();
    itemsScaleLevel = [
      SelectionItemModel(
          value: ScaleLevel.KHONG_THUONG_XUYEN,
          title: appContext?.l10n.scaleL1 ?? ''),
      SelectionItemModel(
          value: ScaleLevel.DUOI_150_THANG,
          title: appContext?.l10n.scaleL2 ?? ''),
      SelectionItemModel(
          value: ScaleLevel.DUOI_900_THANG,
          title: appContext?.l10n.scaleL3 ?? ''),
      SelectionItemModel(
          value: ScaleLevel.DUOI_3000_THANG,
          title: appContext?.l10n.scaleL4 ?? ''),
      SelectionItemModel(
          value: ScaleLevel.DUOI_6000_THANG,
          title: appContext?.l10n.scaleL5 ?? ''),
      SelectionItemModel(
          value: ScaleLevel.TREN_6000_THANG,
          title: appContext?.l10n.scaleL6 ?? ''),
    ];
    itemsIndustry = [
      SelectionItemModel(
          value: IndustryType.THOI_TRANG,
          title: appContext?.l10n.fashion ?? ''),
      SelectionItemModel(
          value: IndustryType.MY_PHAM, title: appContext?.l10n.cosmetics ?? ''),
      SelectionItemModel(
          value: IndustryType.NOI_THAT, title: appContext?.l10n.industry ?? ''),
      SelectionItemModel(
          value: IndustryType.ME_VA_BE,
          title: appContext?.l10n.motherAndBaby ?? ''),
      SelectionItemModel(
          value: IndustryType.MAY_TINH,
          title: appContext?.l10n.computers ?? ''),
      SelectionItemModel(
          value: IndustryType.HANG_HOA_DE_VO,
          title: appContext?.l10n.fragileGoods ?? ''),
      SelectionItemModel(
          value: IndustryType.TIVI_VA_THIET_BI_GIA_DUNG,
          title: appContext?.l10n.householdElectrical ?? ''),
      SelectionItemModel(
          value: IndustryType.GIA_DUNG,
          title: appContext?.l10n.houseware ?? ''),
      SelectionItemModel(
          value: IndustryType.XE_MAY_VA_PHUONG_TIEN,
          title: appContext?.l10n.motorcycles ?? ''),
      SelectionItemModel(
          value: IndustryType.CAY_TRONG_VA_NONG_NGHIEP,
          title: appContext?.l10n.drums ?? ''),
      SelectionItemModel(
          value: IndustryType.THUC_PHAM_VA_NONG_SAN,
          title: appContext?.l10n.food ?? ''),
      SelectionItemModel(
          value: IndustryType.DUNG_CU_VA_PHU_KIEN,
          title: appContext?.l10n.sports ?? ''),
      SelectionItemModel(
          value: IndustryType.TRANG_SUC_VA_PHU_KIEN,
          title: appContext?.l10n.jewelry ?? ''),
      SelectionItemModel(
          value: IndustryType.HANG_TIEU_DUNG,
          title: appContext?.l10n.consumables ?? ''),
      SelectionItemModel(
          value: IndustryType.SACH_VA_VAN_PHONG_PHAM,
          title: appContext?.l10n.books ?? ''),
      SelectionItemModel(
          value: IndustryType.KHAC, title: appContext?.l10n.other ?? ''),
    ];
  }

  @override
  void afterFirstLayout(BuildContext context) {}

  @override
  void dispose() {
    _signUpCubit?.close();
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
              context.l10n.welcomeToGiaohang247,
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
                error: state.errorPhone,
              );
            },
          ),
          SizedBox(
            height: 16.h,
          ),
          BlocBuilder<SignUpCubit, SignUpState>(
            builder: (context, state) {
              return CommonTextField(
                controller: _emailEditingController,
                title: context.l10n.email,
                hint: context.l10n.email,
                keyboardType: TextInputType.emailAddress,
                error: state.errorEmail,
              );
            },
          ),
          SizedBox(
            height: 16.h,
          ),
          BlocBuilder<SignUpCubit, SignUpState>(
            builder: (context, state) {
              return CommonTextField(
                controller: _passEditingController,
                title: context.l10n.password,
                hint: context.l10n.password,
                keyboardType: TextInputType.visiblePassword,
                error: state.errorPassword,
                obscureText: !(_signUpCubit?.state.showPass ?? false),
                suffixConstraints:
                    BoxConstraints.tightFor(width: 44.w, height: 20.w),
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
          SizedBox(
            height: 32.h,
          ),
          DeliveryGoButton(
            title: context.l10n.signUpNowPerWord,
            onTap: () {
              String phone = _phoneEditingController.text.trim();
              String email = _emailEditingController.text.trim();
              String pass = _passEditingController.text.trim();
              _signUpCubit?.onTapSignUp(phone: phone, email: email, pass: pass);
            },
          ),
          SizedBox(
            height: 32.h,
          ),
          Text.rich(
            TextSpan(children: [
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
                    SLIRouting.offAllNamed(AppPage.SIGN_IN);
                  },
              ),
            ]),
          ),
        ],
      ),
    );
  }

  void _showSelectionScale() {
    int index = itemsScaleLevel.indexWhere(
        (element) => element.value == _signUpCubit?.state.currentScaleLevel);
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
            itemsIndustry[index].value, itemsIndustry[index].title, selected),
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
                  context.l10n.giaohang247DuetYou,
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
                    error: state.errorShopName,
                  );
                },
              ),
              SizedBox(
                height: 16.h,
              ),
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
                    error: state.errIndustry,
                  );
                },
              ),
              SizedBox(
                height: 16.h,
              ),
              BlocBuilder<SignUpCubit, SignUpState>(
                builder: (context, state) {
                  String? title = itemsScaleLevel
                      .firstWhereOrNull(
                          (item) => item.value == state.currentScaleLevel)
                      ?.title;
                  return CommonDropDown(
                    title: context.l10n.shippingScale,
                    hint: context.l10n.shippingScale,
                    onTap: () => _showSelectionScale(),
                    value: title,
                    error: state.errScale,
                  );
                },
              ),
              SizedBox(
                height: 32.h,
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${context.l10n.tos1} ',
                    ),
                    TextSpan(
                      text: context.l10n.tos2,
                      style: App.appStyle?.bold14?.copyWith(
                        color: App.appColor?.textColor,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Log.t(message: 'dasdasd');
                        },
                    ),
                    TextSpan(
                      text: ' ${context.l10n.and} ',
                    ),
                    TextSpan(
                      text: context.l10n.tos3,
                      style: App.appStyle?.bold14?.copyWith(
                        color: App.appColor?.textColor,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Log.t(message: 'dasdasd');
                        },
                    ),
                    TextSpan(
                      text: ' ${context.l10n.tos4}',
                    ),
                  ],
                ),
                style: App.appStyle?.regular14?.copyWith(
                  color: App.appColor?.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 32.h,
              ),
              DeliveryGoButton(
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
            child: BackButton(
              onPressed: () => _signUpCubit?.previousPage(),
            ),
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
      listener: (context, state) {
        switch (state.changePageViewStatus) {
          case ChangePageViewStatus.next:
            int newPage = state.currentPage + 1;
            animateToPage(newPage);
            break;
          case ChangePageViewStatus.previous:
            int newPage = state.currentPage - 1;
            animateToPage(newPage);
            break;
          default:
            break;
        }
        if (state.error != null && state.error is FirebaseAuthException) {
          DialogUtil.error(
            context,
            title: context.l10n.error,
            content: (state.error as FirebaseAuthException).message ?? '',
            closeText: context.l10n.close,
            retryText: context.l10n.retry,
            isShowRetry: true,
            onTapRetry: () => _signUpCubit?.sendCodeVerify(),
          );
        }
      },
      builder: (context, state) => Scaffold(
        body: ListView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            AspectRatio(
              aspectRatio: 430.0.w / 320.0.h,
              child: Assets.images.imgAds.image(
                fit: BoxFit.cover,
              ),
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
                      children: [
                        _buildSignUpPage(),
                        _buildInfoShop(),
                      ],
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
