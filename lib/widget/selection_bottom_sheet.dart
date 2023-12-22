import 'package:delivery_go/core/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sli_common/sli_common.dart';

class SelectionItemModel<T> {
  final T value;
  final String title;

  SelectionItemModel({required this.value, required this.title});
}

class SelectionBottomSheet<T> extends StatefulWidget {
  final String title;
  final List<SelectionItemModel<T>> data;
  final int? indexSelected;
  final Widget Function(BuildContext, int)? builder;
  final Function(int)? onSelected;
  final bool isIntrinsicHeight;
  final double? height;

  const SelectionBottomSheet({
    Key? key,
    this.title = '',
    required this.data,
    this.indexSelected,
    this.builder,
    this.onSelected,
    this.isIntrinsicHeight = true,
    this.height,
  }) : super(key: key);

  @override
  State<SelectionBottomSheet> createState() => _SelectionBottomSheetState();
}

class _SelectionBottomSheetState extends State<SelectionBottomSheet> {
  List<SelectionItemModel<dynamic>> listShow = [];
  int? indexSelected;

  @override
  void initState() {
    super.initState();
    indexSelected = widget.indexSelected;
    listShow = widget.data;
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetWidget(
      title: widget.title,
      isIntrinsicHeight: widget.isIntrinsicHeight,
      height: widget.height,
      child: SingleChildScrollView(
        child: Column(
          children: List.generate(
            listShow.length,
            (index) => RadioListTile<dynamic>(
              value: listShow[index].value,
              groupValue:
                  indexSelected == null ? null : listShow[indexSelected!].value,
              title: Text(
                listShow[index].title,
                style: App.appStyle?.medium14?.copyWith(
                  color: App.appColor?.textColor,
                ),
              ),
              selectedTileColor: Colors.white,
              activeColor: App.appColor?.primaryColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                setState(() {
                  indexSelected = index;
                });
                if (widget.onSelected != null) {
                  widget.onSelected!(index);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class MultiSelectionBottomSheet<T> extends StatefulWidget {
  final String title;
  final List<SelectionItemModel<T>> data;
  final List<int> indexSelected;
  final Widget Function(BuildContext, int)? builder;
  final Function(int, bool)? onSelected;
  final bool isIntrinsicHeight;
  final double? height;

  const MultiSelectionBottomSheet({
    Key? key,
    this.title = '',
    required this.data,
    this.indexSelected = const [],
    this.builder,
    this.onSelected,
    this.isIntrinsicHeight = true,
    this.height,
  }) : super(key: key);

  @override
  State<MultiSelectionBottomSheet> createState() =>
      _MultiSelectionBottomSheetState();
}

class _MultiSelectionBottomSheetState extends State<MultiSelectionBottomSheet> {
  List<SelectionItemModel<dynamic>> listShow = [];
  List<int> indexSelected = [];

  @override
  void initState() {
    super.initState();
    for (var element in widget.indexSelected) {
      indexSelected.add(element);
    }
    indexSelected = widget.indexSelected.map((e) => e).toList();
    listShow = widget.data;
  }

  Widget buildItem(index) {
    bool isSelected = indexSelected.contains(index);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      child: InkWell(
        onTap: () {
          setState(() {
            isSelected ? indexSelected.remove(index) : indexSelected.add(index);
          });
          if (widget.onSelected != null) {
            widget.onSelected!(index, !isSelected);
          }
        },
        child: Row(
          children: [
            Container(
              width: 16.w,
              height: 16.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.r),
                border:
                    Border.all(color: App.appColor!.borderColor!, width: 1.0),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 12.w,
                      color: App.appColor?.primaryColor,
                    )
                  : null,
            ),
            Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  listShow[index].title,
                  style: App.appStyle?.medium14?.copyWith(
                    color: App.appColor?.textColor,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetWidget(
      title: widget.title,
      isIntrinsicHeight: widget.isIntrinsicHeight,
      height: widget.height,
      child: SingleChildScrollView(
        child: Column(
          children: List.generate(
            listShow.length,
            (index) => buildItem(index),
          ),
        ),
      ),
    );
  }
}
