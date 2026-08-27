import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_cubit_base/di/injection.dart';
import 'package:bloc_cubit_base/presentation/home_page/cubit/home_page_cubit.dart';

Widget homePageScreenBuilder() => BlocProvider<HomePageCubit>(
  create: (_) => Injector.getIt.get<HomePageCubit>(),
  child: const HomePageScreen(),
);

class HomePageScreen extends StatelessWidget {
  const HomePageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}
