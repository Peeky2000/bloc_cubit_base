import 'package:bloc_cubit_base/core/app/app.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/core/common/route.dart';
import 'package:bloc_cubit_base/core/routing/routing.dart';
import 'package:bloc_cubit_base/di/injection.dart';
import 'package:bloc_cubit_base/l10n/l10n.dart';
import 'package:bloc_cubit_base/presentation/account/cubit/account_cubit.dart';
import 'package:bloc_cubit_base/presentation/global_handler.dart';
import 'package:bloc_cubit_base/widget/app_primary_button.dart';
import 'package:bloc_cubit_base/widget/loading_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sli_common/sli_common.dart'
    show DialogUtil, SliIcons, SliSpacing, SliSurface;

/// Route builder: the only place this feature resolves from the DI graph.
Widget accountScreenBuilder() => BlocProvider<AccountCubit>(
  create: (_) => Injector.getIt.get<AccountCubit>()..load(),
  child: const AccountScreen(),
);

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadingScreen<AccountCubit, AccountState>(
      listenWhen: (previous, current) => previous.effect != current.effect,
      listener: (context, state) {
        final cubit = context.read<AccountCubit>();
        switch (state.effect?.value) {
          case AccountConfirmLogoutEffect():
            DialogUtil.confirm<void>(
              context,
              content: context.l10n.logoutConfirm,
              submitText: context.l10n.logout,
              cancelText: context.l10n.cancel,
              onTapSubmit: cubit.logout,
            );
          case AccountNavigateSignInEffect():
            SLIRouting.offAllNamed(AppPage.signIn);
          case AccountShowErrorEffect(:final error):
            handleErrorResponse(context, error, onRetry: cubit.logout);
          case null:
            break;
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.accountTitle)),
        body: ListView(
          padding: EdgeInsets.all(SliSpacing.lg),
          children: [
            SliSurface(
              child: Column(
                children: [
                  _AccountRow(
                    icon: SliIcons.mail,
                    label: context.l10n.email,
                    value: state.email,
                  ),
                  _AccountRow(
                    icon: SliIcons.phone,
                    label: context.l10n.phoneNumber,
                    value: state.phone,
                  ),
                  _AccountRow(
                    icon: SliIcons.user,
                    label: context.l10n.accountRole,
                    value: state.role,
                  ),
                ],
              ),
            ),
            SizedBox(height: SliSpacing.xxl),
            AppPrimaryButton(
              title: context.l10n.logout,
              isDisable: state.loading == LoadingStatus.loading,
              onTap: () => context.read<AccountCubit>().onTapLogout(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = (value == null || value!.isEmpty)
        ? context.l10n.accountEmptyValue
        : value!;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SliSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: App.appColor?.iconColor),
          SizedBox(width: SliSpacing.md),
          Expanded(
            child: Text(
              label,
              style: App.appStyle?.medium14?.copyWith(
                color: App.appColor?.textColorLight,
              ),
            ),
          ),
          Text(
            text,
            style: App.appStyle?.medium14?.copyWith(
              color: App.appColor?.textColor,
            ),
          ),
        ],
      ),
    );
  }
}
