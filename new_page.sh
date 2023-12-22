#!/bin/bash

prefix=""
name_page=""
name_page_lower=""
type=""
package=""

getPackageName() {
  i=1
      while read line; do
  
      if [[ $line == *"name: "* ]]; then
          package="${line/name: /}"
          break
      fi
      i=$((i+1))
      done < $PWD/pubspec.yaml
}

makeScreenFile() {
  echo "import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:$package/core/mixin/after_layout.dart';
import 'package:$package/di/injection.dart';
import 'package:$package/presentation/${prefix}/cubit/${prefix}_cubit.dart';

Widget ${name_page_lower}ScreenBuilder() => BlocProvider<${name_page}Cubit>(
      create: (_) => Injector.getIt.get<${name_page}Cubit>(),
      child: const ${name_page}Screen(),
    );

class ${name_page}Screen extends StatefulWidget {
  const ${name_page}Screen({Key? key}) : super(key: key);

  @override
  _${name_page}ScreenState createState() => _${name_page}ScreenState();
}

class _${name_page}ScreenState extends State<${name_page}Screen> with AfterLayoutMixin {
  ${name_page}Cubit? _${name_page_lower}Cubit;

  @override
  void initState() {
    super.initState();
    _${name_page_lower}Cubit = context.read<${name_page}Cubit>();
  }

  @override
  void afterFirstLayout(BuildContext context) {}

  @override
  void dispose() {
    _${name_page_lower}Cubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
" > "./lib/presentation/${prefix}/view/${prefix}_screen.dart"
}

makeCubitFile() {
  echo "import 'package:equatable/equatable.dart';
import 'package:$package/core/base_component/base_app_state.dart';
import 'package:$package/core/base_component/base_cubit.dart';
import 'package:$package/core/common/enum.dart';

part '${prefix}_state.dart';

class ${name_page}Cubit extends BaseCubit<${name_page}State> {
  ${name_page}Cubit() : super(${name_page}State.initial());
}
" > "./lib/presentation/${prefix}/cubit/${prefix}_cubit.dart"
}

makeStateFile() {
  echo "part of '${prefix}_cubit.dart';

class ${name_page}State extends BaseAppState with EquatableMixin {
  ${name_page}State({
    required LoadingStatus loading,
    dynamic error,
  }) : super(loading: loading, error: error);

  factory ${name_page}State.initial() {
    return ${name_page}State(
      loading: LoadingStatus.initial,
      error: null,
    );
  }

  ${name_page}State copyWith({LoadingStatus? loading, dynamic error}) {
    return ${name_page}State(
      loading: loading ?? this.loading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, error];
}
" > "./lib/presentation/${prefix}/cubit/${prefix}_state.dart"
}

makeCubitListFile() {
  echo "import 'package:equatable/equatable.dart';
import 'package:$package/core/base_component/base_app_list_state.dart';
import 'package:$package/core/base_component/base_list_cubit.dart';
import 'package:$package/widget/loading_list_screen.dart';

part '${prefix}_state.dart';

class ${name_page}Cubit extends BaseListCubit<${name_page}State> {
  ${name_page}Cubit() : super(${name_page}State.initial());
}
" > "./lib/presentation/${prefix}/cubit/${prefix}_cubit.dart"
}

makeStateListFile() {
  echo "part of '${prefix}_cubit.dart';

class ${name_page}State extends BaseAppListState<T> with EquatableMixin {
  ${name_page}State({
    required LoadingListModel<T> loadingListModel,
    dynamic error,
  }) : super(loadingListModel: loadingListModel, error: error);

  factory ${name_page}State.initial() {
    return ${name_page}State(
      loadingListModel: LoadingListModel<T>(),
      error: null,
    );
  }

  ${name_page}State copyWith({LoadingListModel<T>? loadingListModel, dynamic error}) {
    return ${name_page}State(
      loadingListModel: loadingListModel ?? this.loadingListModel,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loadingListModel, error];
}
" > "./lib/presentation/${prefix}/cubit/${prefix}_state.dart"
}

while getopts n:p:t: flag
do
  case "${flag}" in
    n) 
      name_page=${OPTARG}
      name_page_lower="$(echo ${name_page:0:1} | tr '[:upper:]' '[:lower:]')${name_page:1}"
      ;;
    p) prefix=${OPTARG};;
    t) type=${OPTARG};;
    *)
      echo "Please add flags -n and -p to set value for Screen Name and Prefix name file"
      echo "If you want to gen cubit for list screen using -t with input [list/l]"
      exit 1
    ;;
  esac
done

if [ -z "$name_page" -o -z "$prefix" ]; then
  echo "Please add flags -n and -p to set value for Screen Name and Prefix name file"
  exit 1
fi

if [ ! -d ./lib/presentation/"${prefix}"/view ]; then
  mkdir -p "./lib/presentation/${prefix}/view"
fi

if [ ! -d ./lib/presentation/"${prefix}"/cubit ]; then
  mkdir -p "./lib/presentation/${prefix}/cubit"
fi

getPackageName
makeScreenFile
if [[ $type == "l" || $type == "list" ]]; then
  makeCubitListFile
  makeStateListFile
else
  makeCubitFile
  makeStateFile
fi