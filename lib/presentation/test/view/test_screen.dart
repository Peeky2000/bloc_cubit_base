import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mOrder/core/mixin/after_layout.dart';
import 'package:mOrder/di/injection.dart';
import 'package:mOrder/presentation/test/cubit/test_cubit.dart';

Widget testScreenBuilder() => BlocProvider<TestCubit>(
      create: (_) => Injector.getIt.get<TestCubit>(),
      child: const TestScreen(),
    );

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> with AfterLayoutMixin {
  TestCubit? _testCubit;

  @override
  void initState() {
    super.initState();
    _testCubit = context.read<TestCubit>();
  }

  @override
  void afterFirstLayout(BuildContext context) {}

  @override
  void dispose() {
    _testCubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

