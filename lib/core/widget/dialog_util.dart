import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mOrder/core/extension/string_extension.dart';
import 'package:mOrder/l10n/l10n.dart';
import 'package:mOrder/core/widget/model/option_sheet_model.dart';

class DialogUtil {
  static bool isShowingDialog = false;
  static String defaultTitle = 'Notification';
  static String defaultTitleError = 'Error';
  static double radiusMaterialDialog = 8.0;
  static TextStyle? confirmStyle;
  static TextStyle? cancelStyle;
  static bool get isShowingFlushBar => Flushbar().isShowing();

  static Future<T?> confirm<T>(
    BuildContext context, {
    String? title,
    String content = '',
    TextStyle? titleStyle,
    TextStyle? contentStyle,
    String? submitText,
    String? cancelText,
    Function? onTapSubmit,
    Function? onTapCancel,
  }) {
    isShowingDialog = true;
    if (Platform.isIOS) {
      return showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => CupertinoAlertDialog(
                title: Text(
                  title ?? defaultTitle,
                  style: titleStyle,
                ),
                content: Text(
                  content,
                  style: contentStyle,
                ),
                actions: <Widget>[
                  CupertinoDialogAction(
                      child: Text(cancelText.isNullOrEmpty ? context.l10n.cancel : cancelText!),
                      onPressed: () {
                        Navigator.of(context).pop();
                        isShowingDialog = false;
                        if (onTapCancel != null) {
                          onTapCancel();
                        }
                      }),
                  CupertinoDialogAction(
                    child: Text(submitText.isNullOrEmpty ? context.l10n.ok : submitText!),
                    onPressed: () {
                      Navigator.of(context).pop();
                      isShowingDialog = false;
                      if (onTapSubmit != null) {
                        onTapSubmit();
                      }
                    },
                  )
                ],
              ));
    }
    return showDialog<T>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text(title ?? defaultTitle)),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMaterialDialog)),
          content: Text(content),
          actions: <Widget>[
            TextButton(
                child: Text(cancelText.isNullOrEmpty ? context.l10n.cancel : cancelText!, style: cancelStyle),
                onPressed: () {
                  Navigator.of(context).pop();
                  isShowingDialog = false;
                  if (onTapCancel != null) {
                    onTapCancel();
                  }
                }),
            TextButton(
              child: Text(submitText.isNullOrEmpty ? context.l10n.ok : submitText!, style: confirmStyle,),
              onPressed: () {
                Navigator.of(context).pop();
                isShowingDialog = false;
                if (onTapSubmit != null) {
                  onTapSubmit();
                }
              },
            )
          ],
        );
      },
    );
  }

  static Future<T?> alert<T>(BuildContext context,
      {String? title,
      String content = '',
      TextStyle? titleStyle,
      TextStyle? contentStyle,
      String? submit,
      Function? onSubmit}) {
    isShowingDialog = true;
    if (Platform.isIOS) {
      return showCupertinoDialog(
        context: context,
        useRootNavigator: false,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(
              title ?? defaultTitle,
              style: titleStyle,
            ),
            content: Text(
              content,
              style: contentStyle,
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                child: Text(submit.isNullOrEmpty ? context.l10n.ok : submit!),
                onPressed: () {
                  isShowingDialog = false;
                  Navigator.of(context).pop();
                  if (onSubmit != null) {
                    onSubmit();
                  }
                },
              )
            ],
          );
        },
      );
    }
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMaterialDialog)),
          title: Center(child: Text(title ?? defaultTitle)),
          titleTextStyle: titleStyle,
          alignment: Alignment.center,
          content: Text(
            content,
            style: contentStyle,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(submit.isNullOrEmpty ? context.l10n.ok : submit!, style: confirmStyle,),
              onPressed: () {
                isShowingDialog = false;
                Navigator.of(context).pop();
                if (onSubmit != null) {
                  onSubmit();
                }
              },
            )
          ],
        );
      },
    );
  }

  static Future<T?> error<T>(BuildContext context,
      {String? title,
      String content = '',
      TextStyle? titleStyle,
      TextStyle? contentStyle,
      bool isShowRetry = false,
      String? retryText,
      Function? onTapRetry,
      String closeText = '',
      Function? onTapClose}) {
    isShowingDialog = true;
    if (Platform.isIOS) {
      return showCupertinoDialog(
        context: context,
        useRootNavigator: false,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(
              title ?? defaultTitleError,
              style: titleStyle,
            ),
            content: Text(
              content,
              style: contentStyle,
            ),
            actions: <Widget>[
              if (isShowRetry)
                CupertinoDialogAction(
                  child: Text(retryText.isNullOrEmpty ? context.l10n.retry : retryText!),
                  onPressed: () {
                    isShowingDialog = false;
                    Navigator.of(context).pop();
                    if (onTapRetry != null) {
                      onTapRetry();
                    }
                  },
                ),
              CupertinoDialogAction(
                child: Text(closeText),
                onPressed: () {
                  isShowingDialog = false;
                  Navigator.of(context).pop();
                  if (onTapClose != null) {
                    onTapClose();
                  }
                },
              )
            ],
          );
        },
      );
    }
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMaterialDialog)),
          title: Center(child: Text(title ?? defaultTitleError)),
          titleTextStyle: titleStyle,
          alignment: Alignment.center,
          content: Text(
            content,
            style: contentStyle,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(closeText, style: cancelStyle,),
              onPressed: () {
                isShowingDialog = false;
                Navigator.of(context).pop();
                if (onTapClose != null) {
                  onTapClose();
                }
              },
            ),
            if (isShowRetry)
              TextButton(
                child: Text(retryText.isNullOrEmpty ? context.l10n.retry : retryText!, style: confirmStyle,),
                onPressed: () {
                  isShowingDialog = false;
                  Navigator.of(context).pop();
                  if (onTapRetry != null) {
                    onTapRetry();
                  }
                },
              )
          ],
        );
      },
    );
  }

  static Future<T?> confirmSheet<T>(
    BuildContext context, {
    String? title,
    TextStyle? titleStyle,
    String? content,
    String? cancelText,
    String? submitText,
    Color? submitColor,
    Color? cancelColor,
  }) {
    return showCupertinoModalPopup(
        context: context,
        useRootNavigator: false,
        builder: (popupContext) {
          return CupertinoActionSheet(
            title: Text(
              title ?? defaultTitle,
              style: titleStyle,
            ),
            message: (content != null && content.isNotEmpty)
                ? Container(
                    alignment: Alignment.center,
                    child: Text(content, style: Theme.of(context).textTheme.bodySmall),
                  )
                : null,
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(popupContext).pop(true);
                },
                child: Text(
                  submitText ?? "Xác nhận",
                  style: TextStyle(
                    color: submitColor ?? const Color(0XFF007AFF),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              )
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(popupContext).pop();
              },
              child: Text(
                cancelText ?? "Hủy",
                style: TextStyle(
                  color: cancelColor ?? const Color(0XFF007AFF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        });
  }

  static Future<T?> option<T>(
    BuildContext context, {
    String? title,
    TextStyle? titleStyle,
    String? content,
    String? cancelText,
    Color? cancelColor,
    Function()? onTapCancel,
    bool barrierDismissible = true,
    required List<OptionSheetModel> options,
  }) {
    if (Platform.isIOS) {
      return showCupertinoModalPopup(
          context: context,
          useRootNavigator: false,
          barrierDismissible: barrierDismissible,
          builder: (popupContext) {
            return CupertinoActionSheet(
              title: Text(
                title ?? defaultTitle,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500),
              ),
              message: (content != null && content.isNotEmpty)
                  ? Container(
                      alignment: Alignment.center,
                      child: Text(content, style: Theme.of(context).textTheme.bodySmall),
                    )
                  : null,
              actions: options
                  .map<CupertinoActionSheetAction>((e) => CupertinoActionSheetAction(
                        onPressed: () {
                          Navigator.of(popupContext).pop();
                          if (e.onTap != null) {
                            e.onTap!();
                          }
                        },
                        child: Text(
                          e.title,
                          style: e.style,
                        ),
                      ))
                  .toList(),
              cancelButton: CupertinoActionSheetAction(
                onPressed: () {
                  if (onTapCancel != null) {
                    onTapCancel();
                  }
                  Navigator.of(popupContext).pop();
                },
                child: Text(
                  cancelText ?? "Hủy",
                  style: TextStyle(
                    color: cancelColor ?? const Color(0XFF007AFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          });
    }
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) {
        List<SimpleDialogOption> simpleOption = options
            .map(
              (e) => SimpleDialogOption(
            child: Text(
              e.title,
              style: e.style,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              if (e.onTap != null) {
                e.onTap!();
              }
            },
          ),
        )
            .toList();
        simpleOption.add(
          SimpleDialogOption(
            child: Text(
              cancelText ?? 'Huỷ',
              style: TextStyle(
                color: cancelColor ?? Colors.redAccent,
              ),
            ),
            onPressed: () {
              if (onTapCancel != null) {
                onTapCancel();
              }
              Navigator.of(context).pop();
            },
          ),
        );
        return SimpleDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)
          ),
          title: Text(title ?? defaultTitle, style: titleStyle),
          children: simpleOption,
        );
      },
    );
  }

  static showFlushBar(BuildContext context, String message,
      {Color? backgroundColor,
        Widget? iconFlushBar,
        Duration duration = const Duration(seconds: 2)}) {
    Flushbar(
      backgroundColor: backgroundColor ?? Colors.green,
      flushbarStyle: FlushbarStyle.GROUNDED,
      messageColor: Colors.white,
      duration: duration,
      flushbarPosition: FlushbarPosition.TOP,
      icon: iconFlushBar ??
          const Icon(
            Icons.check_circle_rounded,
            color: Colors.white,
          ),
      message: message,
    ).show(context);
  }
}
