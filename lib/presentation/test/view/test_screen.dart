import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_cubit_base/di/injection.dart';
import 'package:bloc_cubit_base/presentation/test/cubit/test_cubit.dart';

Widget testScreenBuilder() => BlocProvider<TestCubit>(
  create: (_) => Injector.getIt.get<TestCubit>(),
  child: const TestScreen(),
);

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
