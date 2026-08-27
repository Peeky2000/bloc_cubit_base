import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:bloc_cubit_base/core/extension/string_extension.dart';
import 'package:bloc_cubit_base/core/widget/expanded_widget.dart';

class CommonTextField extends StatelessWidget {
  static CommonTextFieldStyle commonTextFieldStyle =
      const CommonTextFieldStyle();

  final String? title;
  final String? note;
  final TextEditingController? controller;
  final String? hint;
  final String? error;
  final Function(String)? onChange;
  final Function()? onTap;
  final Function(String)? onSubmit;
  final Function()? onEditingComplete;
  final int maxLine;
  final int? minLine;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final TextAlign textAlign;
  final bool? enabled;
  final bool autofocus;
  final TextInputType? keyboardType;
  final bool readOnly;
  final bool obscureText;
  final FocusNode? focusNode;
  final Color? cursorColor;
  final List<TextInputFormatter>? inputFormatters;
  final bool? showCursor;
  final TextStyle? titleStyle;
  final TextStyle? labelStyle;
  final TextStyle? noteStyle;
  final TextStyle? hintStyle;
  final TextStyle? errorStyle;
  final Color? fillColor;
  final bool? filled;
  final Widget? suffix;
  final BoxConstraints? suffixConstraints;
  final Widget? prefix;
  final BoxConstraints? prefixBoxConstrains;
  final int? hintMaxLine;
  final bool? alignLabelWithHint;
  final EdgeInsetsGeometry? contentPadding;
  final double? radius;
  final Color? borderColor;
  final Color? disableBorderColor;
  final Color? enableBorderColor;
  final Color? errorBorderColor;
  final Color? focusedBorderColor;
  final Color? focusedErrorBorderColor;
  final bool isUnderline;
  final double borderWidth;
  final bool? isUseDefaultError;
  final String? counterText;
  final TextStyle? counterStyle;
  final Widget? counter;

  InputBorder get border {
    if (!(isUseDefaultError ?? commonTextFieldStyle.isUseDefaultError) &&
        error.isNotNullOrEmpty) {
      return isUnderline
          ? UnderlineInputBorder(
              borderSide: BorderSide(
                color:
                    errorBorderColor ?? commonTextFieldStyle.errorBorderColor!,
                width: commonTextFieldStyle.borderWidth ?? borderWidth,
              ),
            )
          : OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                radius ?? commonTextFieldStyle.borderRadius,
              ),
              borderSide: BorderSide(
                color:
                    errorBorderColor ?? commonTextFieldStyle.errorBorderColor!,
                width: commonTextFieldStyle.borderWidth ?? borderWidth,
              ),
            );
    }
    return isUnderline
        ? UnderlineInputBorder(
            borderSide: BorderSide(
              color: borderColor ?? commonTextFieldStyle.borderColor!,
              width: commonTextFieldStyle.borderWidth ?? borderWidth,
            ),
          )
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              radius ?? commonTextFieldStyle.borderRadius,
            ),
            borderSide: BorderSide(
              color: borderColor ?? commonTextFieldStyle.borderColor!,
              width: commonTextFieldStyle.borderWidth ?? borderWidth,
            ),
          );
  }

  InputBorder get focusedBorder {
    if (!(isUseDefaultError ?? commonTextFieldStyle.isUseDefaultError) &&
        error.isNotNullOrEmpty) {
      return isUnderline
          ? UnderlineInputBorder(
              borderSide: BorderSide(
                color:
                    focusedErrorBorderColor ??
                    commonTextFieldStyle.focusedErrorBorderColor!,
                width: commonTextFieldStyle.borderWidth ?? borderWidth,
              ),
            )
          : OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                radius ?? commonTextFieldStyle.borderRadius,
              ),
              borderSide: BorderSide(
                color:
                    focusedErrorBorderColor ??
                    commonTextFieldStyle.focusedErrorBorderColor!,
                width: commonTextFieldStyle.borderWidth ?? borderWidth,
              ),
            );
    }
    return isUnderline
        ? UnderlineInputBorder(
            borderSide: BorderSide(
              color:
                  focusedBorderColor ??
                  commonTextFieldStyle.focusedBorderColor!,
              width: commonTextFieldStyle.borderWidth ?? borderWidth,
            ),
          )
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              radius ?? commonTextFieldStyle.borderRadius,
            ),
            borderSide: BorderSide(
              color:
                  focusedBorderColor ??
                  commonTextFieldStyle.focusedBorderColor!,
              width: commonTextFieldStyle.borderWidth ?? borderWidth,
            ),
          );
  }

  InputBorder get enabledBorder {
    if (!(isUseDefaultError ?? commonTextFieldStyle.isUseDefaultError) &&
        error.isNotNullOrEmpty) {
      return isUnderline
          ? UnderlineInputBorder(
              borderSide: BorderSide(
                color:
                    errorBorderColor ?? commonTextFieldStyle.errorBorderColor!,
                width: commonTextFieldStyle.borderWidth ?? borderWidth,
              ),
            )
          : OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                radius ?? commonTextFieldStyle.borderRadius,
              ),
              borderSide: BorderSide(
                color:
                    errorBorderColor ?? commonTextFieldStyle.errorBorderColor!,
                width: commonTextFieldStyle.borderWidth ?? borderWidth,
              ),
            );
    }
    return isUnderline
        ? UnderlineInputBorder(
            borderSide: BorderSide(
              color:
                  enableBorderColor ?? commonTextFieldStyle.enableBorderColor!,
              width: commonTextFieldStyle.borderWidth ?? borderWidth,
            ),
          )
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              radius ?? commonTextFieldStyle.borderRadius,
            ),
            borderSide: BorderSide(
              color:
                  enableBorderColor ?? commonTextFieldStyle.enableBorderColor!,
              width: commonTextFieldStyle.borderWidth ?? borderWidth,
            ),
          );
  }

  const CommonTextField({
    super.key,
    this.title,
    this.note,
    this.controller,
    this.hint,
    this.error,
    this.onChange,
    this.onTap,
    this.onSubmit,
    this.onEditingComplete,
    this.maxLine = 1,
    this.minLine,
    this.maxLength,
    this.textInputAction,
    this.textAlign = TextAlign.start,
    this.enabled,
    this.autofocus = false,
    this.keyboardType,
    this.readOnly = false,
    this.obscureText = false,
    this.focusNode,
    this.cursorColor,
    this.inputFormatters,
    this.showCursor,
    this.titleStyle,
    this.labelStyle,
    this.noteStyle,
    this.hintStyle,
    this.errorStyle,
    this.fillColor,
    this.filled,
    this.suffix,
    this.suffixConstraints,
    this.prefix,
    this.prefixBoxConstrains,
    this.hintMaxLine,
    this.alignLabelWithHint,
    this.contentPadding,
    this.radius,
    this.borderColor,
    this.disableBorderColor,
    this.enableBorderColor,
    this.errorBorderColor,
    this.focusedBorderColor,
    this.focusedErrorBorderColor,
    this.isUnderline = false,
    this.borderWidth = 1.0,
    this.isUseDefaultError,
    this.counterText,
    this.counterStyle,
    this.counter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotNullOrEmpty)
          Padding(
            padding:
                commonTextFieldStyle.titlePadding ??
                const EdgeInsets.only(bottom: 12.0),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: title!,
                    style:
                        titleStyle ??
                        commonTextFieldStyle.titleStyle ??
                        const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  TextSpan(
                    text: note ?? '',
                    style:
                        noteStyle ??
                        commonTextFieldStyle.noteStyle ??
                        const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        TextField(
          controller: controller,
          onTap: onTap,
          onChanged: onChange,
          onSubmitted: onSubmit,
          onEditingComplete: onEditingComplete,
          maxLines: maxLine,
          maxLength: maxLength,
          minLines: minLine,
          textInputAction: textInputAction,
          textAlign: textAlign,
          enabled: enabled,
          autofocus: autofocus,
          keyboardType: keyboardType,
          readOnly: readOnly,
          obscureText: obscureText,
          focusNode: focusNode,
          cursorColor: cursorColor,
          inputFormatters: inputFormatters,
          showCursor: showCursor,
          style: labelStyle ?? commonTextFieldStyle.labelStyle,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: hintStyle ?? commonTextFieldStyle.hintStyle,
            fillColor: fillColor ?? commonTextFieldStyle.filledColor,
            filled: filled ?? commonTextFieldStyle.filledColor != null,
            suffixIcon: suffix,
            suffixIconConstraints: suffixConstraints,
            prefixIcon: prefix,
            prefixIconConstraints: prefixBoxConstrains,
            hintMaxLines: hintMaxLine,
            alignLabelWithHint: alignLabelWithHint,
            isDense: true,
            counterText: counterText,
            counterStyle: counterStyle,
            counter: counter,
            errorText:
                (isUseDefaultError ?? commonTextFieldStyle.isUseDefaultError)
                ? (error.isNotNullOrEmpty ? error : null)
                : null,
            errorStyle: errorStyle ?? commonTextFieldStyle.errorStyle,
            contentPadding:
                contentPadding ?? commonTextFieldStyle.contentPadding,
            errorMaxLines: 2,
            border: border,
            disabledBorder: isUnderline
                ? UnderlineInputBorder(
                    borderSide: BorderSide(
                      color:
                          disableBorderColor ??
                          commonTextFieldStyle.disableBorderColor!,
                      width: commonTextFieldStyle.borderWidth ?? borderWidth,
                    ),
                  )
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      radius ?? commonTextFieldStyle.borderRadius,
                    ),
                    borderSide: BorderSide(
                      color:
                          disableBorderColor ??
                          commonTextFieldStyle.disableBorderColor!,
                      width: 1.0,
                    ),
                  ),
            focusedBorder: focusedBorder,
            enabledBorder: enabledBorder,
            errorBorder: isUnderline
                ? UnderlineInputBorder(
                    borderSide: BorderSide(
                      color:
                          errorBorderColor ??
                          commonTextFieldStyle.errorBorderColor!,
                      width: commonTextFieldStyle.borderWidth ?? borderWidth,
                    ),
                  )
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      radius ?? commonTextFieldStyle.borderRadius,
                    ),
                    borderSide: BorderSide(
                      color:
                          errorBorderColor ??
                          commonTextFieldStyle.errorBorderColor!,
                      width: commonTextFieldStyle.borderWidth ?? borderWidth,
                    ),
                  ),
            focusedErrorBorder: isUnderline
                ? UnderlineInputBorder(
                    borderSide: BorderSide(
                      color:
                          focusedErrorBorderColor ??
                          commonTextFieldStyle.focusedErrorBorderColor!,
                      width: commonTextFieldStyle.borderWidth ?? borderWidth,
                    ),
                  )
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      radius ?? commonTextFieldStyle.borderRadius,
                    ),
                    borderSide: BorderSide(
                      color:
                          focusedErrorBorderColor ??
                          commonTextFieldStyle.focusedErrorBorderColor!,
                      width: commonTextFieldStyle.borderWidth ?? borderWidth,
                    ),
                  ),
          ),
        ),
        if (!(isUseDefaultError ?? commonTextFieldStyle.isUseDefaultError))
          commonTextFieldStyle.errorBuilder != null
              ? commonTextFieldStyle.errorBuilder!(error)
              : ExpandedWidget(
                  expand: error.isNotNullOrEmpty,
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      error ?? '',
                      style: errorStyle ?? commonTextFieldStyle.errorStyle,
                    ),
                  ),
                ),
      ],
    );
  }
}

class CommonTextFieldStyle {
  final TextStyle? titleStyle;
  final TextStyle? noteStyle;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final TextStyle? errorStyle;
  final EdgeInsetsGeometry? contentPadding;
  final Color? borderColor;
  final Color? disableBorderColor;
  final Color? enableBorderColor;
  final Color? errorBorderColor;
  final Color? focusedBorderColor;
  final Color? focusedErrorBorderColor;
  final double borderRadius;
  final EdgeInsetsGeometry? titlePadding;
  final Color? filledColor;
  final double? borderWidth;
  final bool isUseDefaultError;
  final Widget Function(String?)? errorBuilder;

  const CommonTextFieldStyle({
    this.titleStyle = const TextStyle(
      color: Colors.black,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    this.noteStyle = const TextStyle(
      color: Colors.grey,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    this.labelStyle = const TextStyle(
      color: Colors.black,
      fontSize: 16,
      fontWeight: FontWeight.normal,
    ),
    this.hintStyle = const TextStyle(
      color: Colors.grey,
      fontSize: 16,
      fontWeight: FontWeight.normal,
    ),
    this.errorStyle = const TextStyle(
      color: Colors.redAccent,
      fontSize: 14,
      fontWeight: FontWeight.normal,
    ),
    this.contentPadding = const EdgeInsets.all(8.0),
    this.borderColor = Colors.grey,
    this.focusedErrorBorderColor = Colors.redAccent,
    this.disableBorderColor = const Color(0xFFE0E0E0),
    this.enableBorderColor = Colors.grey,
    this.errorBorderColor = Colors.redAccent,
    this.focusedBorderColor = Colors.blue,
    this.borderRadius = 8.0,
    this.titlePadding,
    this.filledColor,
    this.borderWidth,
    this.isUseDefaultError = true,
    this.errorBuilder,
  });
}

class ThousandsFormatter extends NumberInputFormatter {
  static final NumberFormat _formatter = NumberFormat("###,###,###.##");

  final FilteringTextInputFormatter _decimalFormatter;
  final String _decimalSeparator;
  final RegExp _decimalRegex;

  final NumberFormat? formatter;
  final bool allowFraction;

  ThousandsFormatter({this.formatter, this.allowFraction = false})
    : _decimalSeparator = (formatter ?? _formatter).symbols.DECIMAL_SEP,
      _decimalRegex = RegExp(
        allowFraction
            ? '[0-9]+([${(formatter ?? _formatter).symbols.DECIMAL_SEP}])?'
            : r'\d+',
      ),
      _decimalFormatter = FilteringTextInputFormatter.allow(
        RegExp(
          allowFraction
              ? '[0-9]+([${(formatter ?? _formatter).symbols.DECIMAL_SEP}])?'
              : r'\d+',
        ),
      );

  @override
  String _formatPattern(String? digits) {
    if (digits == null || digits.isEmpty) return '';
    num number;
    if (allowFraction) {
      String decimalDigits = digits;
      if (_decimalSeparator != '.') {
        decimalDigits = digits.replaceFirst(RegExp(_decimalSeparator), '.');
      }
      number = double.tryParse(decimalDigits) ?? 0.0;
    } else {
      number = int.tryParse(digits) ?? 0;
    }
    final result = (formatter ?? _formatter).format(number);
    if (allowFraction && digits.endsWith(_decimalSeparator)) {
      return '$result$_decimalSeparator';
    }
    return result;
  }

  @override
  TextEditingValue _formatValue(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _decimalFormatter.formatEditUpdate(oldValue, newValue);
  }

  @override
  bool _isUserInput(String s) {
    return s == _decimalSeparator || _decimalRegex.firstMatch(s) != null;
  }
}

///
/// An implementation of [NumberInputFormatter] that converts a numeric input
/// to credit card number form (4-digit grouping). For example, a input of
/// `12345678` should be formatted to `1234 5678`.
///
class CreditCardFormatter extends NumberInputFormatter {
  static final RegExp _digitOnlyRegex = RegExp(r'\d+');
  static final FilteringTextInputFormatter _digitOnlyFormatter =
      FilteringTextInputFormatter.allow(_digitOnlyRegex);

  final String separator;

  CreditCardFormatter({this.separator = ' '});

  @override
  String _formatPattern(String digits) {
    StringBuffer buffer = StringBuffer();
    int offset = 0;
    int count = min(4, digits.length);
    final length = digits.length;
    for (; count <= length; count += min(4, max(1, length - count))) {
      buffer.write(digits.substring(offset, count));
      if (count < length) {
        buffer.write(separator);
      }
      offset = count;
    }
    return buffer.toString();
  }

  @override
  TextEditingValue _formatValue(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _digitOnlyFormatter.formatEditUpdate(oldValue, newValue);
  }

  @override
  bool _isUserInput(String s) {
    return _digitOnlyRegex.firstMatch(s) != null;
  }
}

///
/// An abstract class extends from [TextInputFormatter] and does numeric filter.
/// It has an abstract method `_format()` that lets its children override it to
/// format input displayed on [TextField]
///
abstract class NumberInputFormatter extends TextInputFormatter {
  TextEditingValue? _lastNewValue;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    /// nothing changes, nothing to do
    if (newValue.text == _lastNewValue?.text) {
      return newValue;
    }
    _lastNewValue = newValue;

    /// remove all invalid characters
    newValue = _formatValue(oldValue, newValue);

    /// current selection
    int selectionIndex = newValue.selection.end;

    /// format original string, this step would add some separator
    /// characters to original string
    final newText = _formatPattern(newValue.text);

    /// count number of inserted character in new string
    int insertCount = 0;

    /// count number of original input character in new string
    int inputCount = 0;
    for (int i = 0; i < newText.length && inputCount < selectionIndex; i++) {
      final character = newText[i];
      if (_isUserInput(character)) {
        inputCount++;
      } else {
        insertCount++;
      }
    }

    /// adjust selection according to number of inserted characters staying before
    /// selection
    selectionIndex += insertCount;
    selectionIndex = min(selectionIndex, newText.length);

    /// if selection is right after an inserted character, it should be moved
    /// backward, this adjustment prevents an issue that user cannot delete
    /// characters when cursor stands right after inserted characters
    if (selectionIndex - 1 >= 0 &&
        selectionIndex - 1 < newText.length &&
        !_isUserInput(newText[selectionIndex - 1])) {
      selectionIndex--;
    }

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: selectionIndex),
      composing: TextRange.empty,
    );
  }

  /// check character from user input or being inserted by pattern formatter
  bool _isUserInput(String s);

  /// format user input with pattern formatter
  String _formatPattern(String digits);

  /// validate user input
  TextEditingValue _formatValue(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  );
}

class DateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue prevText,
    TextEditingValue currText,
  ) {
    int selectionIndex;

    // Get the previous and current input strings
    String pText = prevText.text;
    String cText = currText.text;
    // Abbreviate lengths
    int cLen = cText.length;
    int pLen = pText.length;

    if (cLen == 1) {
      // Can only be 0, 1, 2 or 3
      if (int.parse(cText) > 3) {
        // Remove char
        cText = '';
      }
    } else if (cLen == 2 && pLen == 1) {
      // Days cannot be greater than 31
      int dd = int.parse(cText.substring(0, 2));
      if (dd == 0 || dd > 31) {
        // Remove char
        cText = cText.substring(0, 1);
      } else {
        // Add a / char
        cText += '/';
      }
    } else if (cLen == 4) {
      // Can only be 0 or 1
      if (int.parse(cText.substring(3, 4)) > 1) {
        // Remove char
        cText = cText.substring(0, 3);
      }
    } else if (cLen == 5 && pLen == 4) {
      // Month cannot be greater than 12
      int mm = int.parse(cText.substring(3, 5));
      if (mm == 0 || mm > 12) {
        // Remove char
        cText = cText.substring(0, 4);
      } else {
        // Add a / char
        cText += '/';
      }
    } else if ((cLen == 3 && pLen == 4) || (cLen == 6 && pLen == 7)) {
      // Remove / char
      cText = cText.substring(0, cText.length - 1);
    } else if (cLen == 3 && pLen == 2) {
      if (int.parse(cText.substring(2, 3)) > 1) {
        // Replace char
        cText = '${cText.substring(0, 2)}/';
      } else {
        // Insert / char
        cText =
            '${cText.substring(0, pLen)}/${cText.substring(pLen, pLen + 1)}';
      }
    } else if (cLen == 6 && pLen == 5) {
      // Can only be 1 or 2 - if so insert a / char
      int y1 = int.parse(cText.substring(5, 6));
      if (y1 < 1 || y1 > 2) {
        // Replace char
        cText = '${cText.substring(0, 5)}/';
      } else {
        // Insert / char
        cText = '${cText.substring(0, 5)}/${cText.substring(5, 6)}';
      }
    } else if (cLen == 7) {
      // Can only be 1 or 2
      int y1 = int.parse(cText.substring(6, 7));
      if (y1 < 1 || y1 > 2) {
        // Remove char
        cText = cText.substring(0, 6);
      }
    } else if (cLen == 8) {
      // Can only be 19 or 20
      int y2 = int.parse(cText.substring(6, 8));
      if (y2 < 19 || y2 > 20) {
        // Remove char
        cText = cText.substring(0, 7);
      }
    }

    selectionIndex = cText.length;
    return TextEditingValue(
      text: cText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
