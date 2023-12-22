import 'package:delivery_go/widget/loading_list_screen.dart';

class BaseAppListState<T> {
  LoadingListModel<T> loadingListModel = LoadingListModel<T>();
  dynamic error;

  BaseAppListState({required this.loadingListModel, this.error});
}
