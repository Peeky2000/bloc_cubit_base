import 'package:equatable/equatable.dart';
import 'package:mOrder/core/base_component/base_app_state.dart';
import 'package:mOrder/core/base_component/base_cubit.dart';
import 'package:mOrder/core/common/enum.dart';

part 'test_state.dart';

class TestCubit extends BaseCubit<TestState> {
  TestCubit() : super(TestState.initial());
}

