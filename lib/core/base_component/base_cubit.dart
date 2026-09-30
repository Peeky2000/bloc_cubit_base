import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/ui_effect.dart';

class BaseCubit<State extends BaseAppState<Object>> extends Cubit<State>
    with UiEffectFactory {
  BaseCubit(super.initialState);

  Future<void> load() async {}
}
