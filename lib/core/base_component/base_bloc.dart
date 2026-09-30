import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/ui_effect.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Base type for features whose event semantics justify classic BLoC.
///
/// Cubit remains the default. Keep event transformer choices in each concrete BLoC so
/// concurrency behavior is explicit at the point of use.
abstract class BaseBloc<Event, State extends BaseAppState<Object>>
    extends Bloc<Event, State>
    with UiEffectFactory {
  BaseBloc(super.initialState);
}
