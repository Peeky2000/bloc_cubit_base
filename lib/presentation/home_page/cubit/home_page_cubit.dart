import 'package:equatable/equatable.dart';
import 'package:delivery_go/core/base_component/base_app_state.dart';
import 'package:delivery_go/core/base_component/base_cubit.dart';
import 'package:delivery_go/core/common/enum.dart';

part 'home_page_state.dart';

class HomePageCubit extends BaseCubit<HomePageState> {
  HomePageCubit() : super(HomePageState.initial());
}
