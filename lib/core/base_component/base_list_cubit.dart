import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:delivery_go/core/base_component/base_app_list_state.dart';

class BaseListCubit<State extends BaseAppListState> extends Cubit<State> {
  bool isHasNexData = false;
  int page = 1;

  BaseListCubit(initialState) : super(initialState);

  Future<void> load() async {}

  Future<void> loadMore() async {}
}
