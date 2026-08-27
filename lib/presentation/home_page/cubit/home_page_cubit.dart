import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:injectable/injectable.dart';

part 'home_page_state.dart';

@injectable
class HomePageCubit extends BaseCubit<HomePageState> {
  HomePageCubit() : super(HomePageState.initial());
}
