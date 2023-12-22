import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:delivery_go/core/base_component/base_app_state.dart';

class BaseCubit<State extends BaseAppState> extends Cubit<State> {
  BaseCubit(initialState) : super(initialState);

  Future<void> load() async {}
}
