import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';

class BaseCubit<State extends BaseAppState> extends Cubit<State> {
  BaseCubit(super.initialState);

  Future<void> load() async {}
}
