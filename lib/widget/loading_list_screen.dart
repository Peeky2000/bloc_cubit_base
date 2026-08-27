import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:bloc_cubit_base/core/base_component/base_app_list_state.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/core/extension/list_extension.dart';
import 'package:bloc_cubit_base/l10n/l10n.dart';

enum LoadingListStyle { ios, android }

class LoadingListScreen<
  B extends StateStreamable<S>,
  S extends BaseAppListState
>
    extends StatelessWidget {
  final RefreshController refreshController;
  final Widget? emptyWidget;
  final Widget Function(BuildContext, S, int) builder;
  final VoidCallback? refreshData;
  final VoidCallback? loadMore;
  final bool dismissible;
  final double opacity;
  final Color color;
  final EdgeInsets? padding;
  final Widget Function(BuildContext, S, int)? separatorBuilder;
  final BlocBuilderCondition<S>? buildWhen;
  final Function(BuildContext, S)? listener;
  final int extendItem;
  final bool reverse;
  final LoadingListStyle? loadingStyle;
  final Widget? header;
  final Widget? footer;
  final bool shrinkWrap;

  const LoadingListScreen({
    super.key,
    required this.refreshController,
    this.emptyWidget,
    required this.builder,
    this.refreshData,
    this.loadMore,
    this.opacity = 0.3,
    this.color = Colors.black,
    this.dismissible = false,
    this.padding,
    this.separatorBuilder,
    this.buildWhen,
    this.listener,
    this.extendItem = 0,
    this.reverse = false,
    this.loadingStyle,
    this.header,
    this.footer,
    this.shrinkWrap = false,
  });

  bool get _checkStyle {
    if (loadingStyle == null) {
      return Platform.isIOS;
    } else {
      return loadingStyle == LoadingListStyle.ios;
    }
  }

  Widget _buildListResult() {
    return BlocListener<B, S>(
      listener: (context, state) {
        if (listener != null) {
          listener!(context, state);
        }
      },
      child: BlocBuilder<B, S>(
        buildWhen:
            buildWhen ??
            (current, old) => current.loadingListModel != old.loadingListModel,
        builder: (context, state) {
          return state.loadingListModel.data.isEmpty &&
                  (state.loadingListModel.loading == LoadingStatus.complete)
              ? emptyWidget ?? const SizedBox()
              : SmartRefresher(
                  controller: refreshController,
                  onRefresh: refreshData,
                  enablePullDown: refreshData != null,
                  enablePullUp: loadMore != null,
                  onLoading: loadMore,
                  reverse: reverse,
                  header:
                      header ??
                      (_checkStyle
                          ? ClassicHeader(
                              canTwoLevelText: context.l10n.canTwoLevelText,
                              releaseText: context.l10n.canRefreshText,
                              idleText: context.l10n.idleRefreshText,
                              completeText: context.l10n.refreshCompleted,
                              refreshingText: context.l10n.refreshingText,
                              failedText: context.l10n.refreshFailedText,
                            )
                          : const MaterialClassicHeader()),
                  footer:
                      footer ??
                      ClassicFooter(
                        canLoadingText: context.l10n.releaseToLoadMore,
                        failedText: context.l10n.loadFail,
                        loadingText: context.l10n.loading,
                        noDataText: context.l10n.noMoreData,
                        idleText: context.l10n.pullUpLoadMore,
                      ),
                  child: ListView.separated(
                    itemCount: state.loadingListModel.data.length + extendItem,
                    itemBuilder: (context, index) =>
                        builder(context, state, index),
                    padding: padding,
                    reverse: reverse,
                    shrinkWrap: shrinkWrap,
                    separatorBuilder: (context, index) {
                      if (separatorBuilder != null) {
                        return separatorBuilder!(context, state, index);
                      }
                      return const SizedBox();
                    },
                  ),
                );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildListResult(),
        BlocBuilder<B, BaseAppListState>(
          builder: (context, state) {
            return state.loadingListModel.loading == LoadingStatus.loading ||
                    state.loadingListModel.loading == LoadingStatus.refresh
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: opacity,
                        child: ModalBarrier(
                          dismissible: dismissible,
                          color: color,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const CupertinoActivityIndicator(radius: 14),
                      ),
                    ],
                  )
                : const SizedBox();
          },
        ),
      ],
    );
  }
}

class LoadingListModel<T> extends Equatable {
  final LoadingStatus loading;
  final List<T> data;

  LoadingListModel({
    this.loading = LoadingStatus.initial,
    List<T> data = const [],
  }) : data = List<T>.unmodifiable(data);

  LoadingListModel<T> addData(T? newData) => newData == null
      ? this
      : LoadingListModel<T>(loading: loading, data: [...data, newData]);

  LoadingListModel<T> addAllData(List<T>? listNewData) =>
      listNewData == null || listNewData.isEmpty
      ? this
      : LoadingListModel<T>(loading: loading, data: [...data, ...listNewData]);

  LoadingListModel<T> insertData(int index, T? newElement) {
    if (newElement == null) {
      return this;
    }
    final updatedData = [...data]..insert(index, newElement);
    return LoadingListModel<T>(loading: loading, data: updatedData);
  }

  LoadingListModel<T> copyWithNewData({LoadingStatus? loading, List<T>? data}) {
    return LoadingListModel<T>(
      loading: loading ?? this.loading,
      data: data ?? [],
    );
  }

  LoadingListModel<T> copyWithAddData({LoadingStatus? loading, List<T>? data}) {
    final newLoadingModel = LoadingListModel<T>(
      loading: loading ?? this.loading,
      data: this.data,
    );
    return newLoadingModel.addAllData(data);
  }

  LoadingListModel<T> copyWithInsertData(
    int index, {
    LoadingStatus? loading,
    T? newElement,
  }) {
    final newLoadingModel = LoadingListModel<T>(
      loading: loading ?? this.loading,
      data: data,
    );
    return newLoadingModel.insertData(index, newElement);
  }

  T? firstWhereOrNull(bool Function(T element) test) {
    return data.firstWhereOrNull(test);
  }

  T firstWhere(bool Function(T element) test, {T Function()? orElse}) {
    return data.firstWhere(test, orElse: orElse);
  }

  @override
  List<Object?> get props => [loading, data];
}
