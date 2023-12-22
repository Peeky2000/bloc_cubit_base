import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:delivery_go/core/mixin/after_layout.dart';
import 'package:delivery_go/di/injection.dart';
import 'package:delivery_go/presentation/home_page/cubit/home_page_cubit.dart';

Widget homePageScreenBuilder() => BlocProvider<HomePageCubit>(
      create: (_) => Injector.getIt.get<HomePageCubit>(),
      child: const HomePageScreen(),
    );

class HomePageScreen extends StatefulWidget {
  const HomePageScreen({Key? key}) : super(key: key);

  @override
  _HomePageScreenState createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> with AfterLayoutMixin {
  HomePageCubit? _homePageCubit;

  @override
  void initState() {
    super.initState();
    _homePageCubit = context.read<HomePageCubit>();
  }

  @override
  void afterFirstLayout(BuildContext context) {}

  @override
  void dispose() {
    _homePageCubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(),
    );
  }
}
