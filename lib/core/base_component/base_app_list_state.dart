import 'package:bloc_cubit_base/widget/loading_list_screen.dart';

class BaseAppListState<T> {
  const BaseAppListState({required this.loadingListModel, this.error});

  final LoadingListModel<T> loadingListModel;
  final Object? error;
}
