import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/presentation/home_page/cubit/home_page_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts with immutable initial state', () {
    final cubit = HomePageCubit();

    expect(cubit.state.loading, LoadingStatus.initial);
    expect(cubit.state.error, isNull);

    cubit.close();
  });

  blocTest<HomePageCubit, HomePageState>(
    'emits no state when no command is invoked',
    build: HomePageCubit.new,
    expect: () => <HomePageState>[],
  );
}
