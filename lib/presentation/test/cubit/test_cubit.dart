import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:injectable/injectable.dart';

part 'test_state.dart';

@injectable
class TestCubit extends BaseCubit<TestState> {
  TestCubit() : super(TestState.initial());
}
