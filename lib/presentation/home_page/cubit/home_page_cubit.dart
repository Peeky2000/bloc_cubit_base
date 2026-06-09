import 'package:equatable/equatable.dart';
import 'package:mOrder/core/base_component/base_app_state.dart';
import 'package:mOrder/core/base_component/base_cubit.dart';
import 'package:mOrder/core/common/enum.dart';

part 'home_page_state.dart';

class HomePageCubit extends BaseCubit<HomePageState> {
  HomePageCubit() : super(HomePageState.initial());
}
