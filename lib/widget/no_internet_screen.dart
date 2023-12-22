import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:delivery_go/core/app/app.dart';
import 'package:delivery_go/core/helper/network/network_checker.dart';
import 'package:delivery_go/di/injection.dart';
import 'package:delivery_go/generated/assets.gen.dart';
import 'package:delivery_go/l10n/l10n.dart';
import 'package:sli_common/sli_common.dart';

class NoInternetScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const NoInternetScreen({Key? key, required this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Assets.images.imgDisconnect.svg(),
              SizedBox(
                height: 16.0.h,
              ),
              StreamBuilder<bool>(
                stream: Injector.getIt
                    .get<NetworkChecker>()
                    .connectController
                    .stream,
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data == true
                        ? l10n.reconnectInternet
                        : l10n.noInternet,
                    textAlign: TextAlign.center,
                    style: App.appStyle?.medium16?.copyWith(
                      color: App.appColor?.borderColor,
                    ),
                  );
                },
              ),
              SizedBox(
                height: 32.0.h,
              ),
              StreamBuilder<bool>(
                  stream: Injector.getIt
                      .get<NetworkChecker>()
                      .connectController
                      .stream,
                  builder: (context, snapshot) {
                    return InkWellButton(
                      title: context.l10n.retry,
                      width: 180.w,
                      onTap: snapshot.data == true
                          ? () {
                              if (Injector.getIt
                                      .get<NetworkChecker>()
                                      .isConnected ==
                                  true) {
                                onRetry();
                              }
                            }
                          : null,
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
