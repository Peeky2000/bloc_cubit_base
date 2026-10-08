/// Pure templates for a new feature that follows this repository's
/// conventions. `tool/scaffold/feature.dart` writes them to disk.
///
/// Every generated file passes `tool/convention/rules.dart`; the scaffold
/// test enforces that.
library;

class ScaffoldOptions {
  const ScaffoldOptions({
    required this.feature,
    this.stateOwner = 'cubit',
    this.withData = false,
    this.domain,
  });

  /// snake_case feature name, such as `order_list`.
  final String feature;

  /// `cubit` (default) or `bloc`.
  final String stateOwner;

  /// Also create entity, model, remote data source, repository and use case.
  final bool withData;

  /// snake_case domain name for the data layer, such as `order`. Defaults to
  /// [feature].
  final String? domain;

  String get domainName => domain ?? feature;
}

final _snake = RegExp(r'^[a-z][a-z0-9_]*$');

String pascal(String snake) => snake
    .split('_')
    .where((p) => p.isNotEmpty)
    .map((p) => p[0].toUpperCase() + p.substring(1))
    .join();

String camel(String snake) {
  final p = pascal(snake);
  return p[0].toLowerCase() + p.substring(1);
}

/// Validates options and returns path -> content for every file to create.
Map<String, String> scaffoldFeature(
  ScaffoldOptions o, {
  String package = 'bloc_cubit_base',
}) {
  if (!_snake.hasMatch(o.feature)) {
    throw FormatException('feature must be snake_case: ${o.feature}');
  }
  if (!_snake.hasMatch(o.domainName)) {
    throw FormatException('domain must be snake_case: ${o.domainName}');
  }
  if (o.stateOwner != 'cubit' && o.stateOwner != 'bloc') {
    throw FormatException('state owner must be cubit or bloc');
  }
  final f = o.feature;
  final F = pascal(f);
  final d = o.domainName;
  final D = pascal(d);
  final kind = o.stateOwner;
  final p = package;
  final files = <String, String>{};

  final useCaseImport = o.withData
      ? "import 'package:$p/domain/use_case/${d}_use_case.dart';\n"
      : '';
  final ctorParam = o.withData ? 'this._useCase' : '';
  final field = o.withData ? '\n  final ${D}UseCase _useCase;\n' : '';
  final loadBody = o.withData
      ? '''
    emit(state.copyWith(loading: LoadingStatus.loading));
    try {
      final items = await _useCase.get${D}s();
      if (isClosed) return;
      emit(state.copyWith(loading: LoadingStatus.complete, items: items));
    } catch (error) {
      if (isClosed) return;
      emit(state.copyWith(loading: LoadingStatus.error, error: error));
      _emitEffect(${F}ShowErrorEffect(error: error));
    }'''
      : '''
    emit(state.copyWith(loading: LoadingStatus.complete));''';
  final entityImport = o.withData
      ? "import 'package:$p/domain/entities/$d/$d.dart';\n"
      : '';
  final itemsField = o.withData ? '\n  final List<$D> items;' : '';
  final itemsCtor = o.withData ? '\n    this.items = const [],' : '';
  final itemsParam = o.withData ? '\n    List<$D>? items,' : '';
  final itemsCopy = o.withData ? '\n      items: items ?? this.items,' : '';
  final itemsProp = o.withData ? ', items' : '';

  if (kind == 'cubit') {
    files['lib/presentation/$f/cubit/${f}_cubit.dart'] =
        '''
import 'package:$p/core/base_component/base_app_state.dart';
import 'package:$p/core/base_component/base_cubit.dart';
import 'package:$p/core/base_component/ui_effect.dart';
import 'package:$p/core/common/enum.dart';
$entityImport$useCaseImport
import 'package:injectable/injectable.dart';

part '${f}_effect.dart';
part '${f}_state.dart';

@injectable
class ${F}Cubit extends BaseCubit<${F}State> {
  ${F}Cubit($ctorParam) : super(${F}State.initial());
$field
  @override
  Future<void> load() async {
$loadBody
  }
${o.withData ? '''
  void _emitEffect(${F}Effect effect) {
    emit(state.copyWith(effect: createEffect(effect)));
  }
''' : ''}}
''';
  } else {
    files['lib/presentation/$f/bloc/${f}_bloc.dart'] =
        '''
import 'package:$p/core/base_component/base_app_state.dart';
import 'package:$p/core/base_component/base_bloc.dart';
import 'package:$p/core/base_component/ui_effect.dart';
import 'package:$p/core/common/enum.dart';
$entityImport$useCaseImport
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part '${f}_effect.dart';
part '${f}_event.dart';
part '${f}_state.dart';

/// BLoC is used because: TODO(scaffold) document the event or concurrency need.
@injectable
class ${F}Bloc extends BaseBloc<${F}Event, ${F}State> {
  ${F}Bloc($ctorParam) : super(${F}State.initial()) {
    on<${F}Started>(_onStarted);
  }
$field
  Future<void> _onStarted(${F}Started event, Emitter<${F}State> emit) async {
${loadBody.replaceAll('_emitEffect(', 'emit(state.copyWith(effect: createEffect(').replaceAll('ShowErrorEffect(error: error));', 'ShowErrorEffect(error: error))));').replaceAll('if (isClosed) return;\n', '')}
  }
}
''';
    files['lib/presentation/$f/bloc/${f}_event.dart'] =
        '''
part of '${f}_bloc.dart';

sealed class ${F}Event {
  const ${F}Event();
}

final class ${F}Started extends ${F}Event {
  const ${F}Started();
}
''';
  }

  files['lib/presentation/$f/$kind/${f}_state.dart'] =
      '''
part of '${f}_$kind.dart';

class ${F}State extends BaseAppState<Object> {
  const ${F}State({
    required super.loading,
    super.error,$itemsCtor
    this.effect,
  });
$itemsField
  final UiEffect<${F}Effect>? effect;

  factory ${F}State.initial() =>
      const ${F}State(loading: LoadingStatus.initial);

  ${F}State copyWith({
    LoadingStatus? loading,
    Object? error,$itemsParam
    UiEffect<${F}Effect>? effect,
  }) {
    return ${F}State(
      loading: loading ?? this.loading,
      error: error,$itemsCopy
      effect: effect ?? this.effect,
    );
  }

  @override
  List<Object?> get props => [loading, error$itemsProp, effect];
}
''';

  files['lib/presentation/$f/$kind/${f}_effect.dart'] =
      '''
part of '${f}_$kind.dart';

/// One-shot UI actions. The screen handles them in a BlocListener.
sealed class ${F}Effect {
  const ${F}Effect();
}

final class ${F}ShowErrorEffect extends ${F}Effect {
  const ${F}ShowErrorEffect({required this.error});

  final Object error;
}
''';

  final owner = kind == 'cubit' ? '${F}Cubit' : '${F}Bloc';
  final create = kind == 'cubit'
      ? 'Injector.getIt.get<$owner>()..load()'
      : 'Injector.getIt.get<$owner>()..add(const ${F}Started())';
  files['lib/presentation/$f/view/${f}_screen.dart'] =
      '''
import 'package:$p/di/injection.dart';
import 'package:$p/presentation/$f/$kind/${f}_$kind.dart';
import 'package:$p/presentation/global_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Route builder: the only place this feature resolves from the DI graph.
Widget ${camel(f)}ScreenBuilder() => BlocProvider<$owner>(
  create: (_) => $create,
  child: const ${F}Screen(),
);

class ${F}Screen extends StatelessWidget {
  const ${F}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<$owner, ${F}State>(
      listenWhen: (previous, current) => previous.effect != current.effect,
      listener: (context, state) {
        switch (state.effect?.value) {
          case ${F}ShowErrorEffect(:final error):
            handleErrorResponse(context, error);
          case null:
            break;
        }
      },
      child: const Scaffold(body: SizedBox.shrink()),
    );
  }
}
''';

  files['test/presentation/${f}_${kind}_test.dart'] = kind == 'cubit'
      ? '''
import 'package:$p/core/common/enum.dart';
import 'package:$p/presentation/$f/cubit/${f}_cubit.dart';
${o.withData ? "import 'package:$p/domain/use_case/${d}_use_case.dart';\nimport 'package:mocktail/mocktail.dart';\n" : ''}import 'package:flutter_test/flutter_test.dart';

void main() {
${o.withData ? '''  late _Mock${D}UseCase useCase;

  setUp(() => useCase = _Mock${D}UseCase());

  test('loads items', () async {
    when(() => useCase.get${D}s()).thenAnswer((_) async => const []);
    final cubit = ${F}Cubit(useCase);
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.loading, LoadingStatus.complete);
  });

  test('publishes an error effect when loading fails', () async {
    when(() => useCase.get${D}s()).thenThrow(StateError('boom'));
    final cubit = ${F}Cubit(useCase);
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.loading, LoadingStatus.error);
    expect(cubit.state.effect?.value, isA<${F}ShowErrorEffect>());
  });
}

class _Mock${D}UseCase extends Mock implements ${D}UseCase {}
''' : '''  test('starts in the initial state', () {
    final cubit = ${F}Cubit();
    addTearDown(cubit.close);

    expect(cubit.state.loading, LoadingStatus.initial);
  });

  test('completes loading', () async {
    final cubit = ${F}Cubit();
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.loading, LoadingStatus.complete);
  });
}
'''}'''
      : '''
import 'package:$p/core/common/enum.dart';
import 'package:$p/presentation/$f/bloc/${f}_bloc.dart';
${o.withData ? "import 'package:$p/domain/use_case/${d}_use_case.dart';\nimport 'package:mocktail/mocktail.dart';\n" : ''}import 'package:flutter_test/flutter_test.dart';

void main() {
  test('completes loading on start', () async {
${o.withData ? '    final useCase = _Mock${D}UseCase();\n    when(() => useCase.get${D}s()).thenAnswer((_) async => const []);\n    final bloc = ${F}Bloc(useCase);\n' : '    final bloc = ${F}Bloc();\n'}    addTearDown(bloc.close);

    bloc.add(const ${F}Started());
    await bloc.stream.firstWhere((s) => s.loading == LoadingStatus.complete);

    expect(bloc.state.loading, LoadingStatus.complete);
  });
}
${o.withData ? '\nclass _Mock${D}UseCase extends Mock implements ${D}UseCase {}\n' : ''}''';

  if (!o.withData) return files;

  files['lib/domain/entities/$d/$d.dart'] =
      '''
/// Domain contract for a $d. Data models implement it; no JSON here.
abstract class $D {
  String? get id;
}
''';
  files['lib/domain/repositories/${d}_repo.dart'] =
      '''
import 'package:$p/domain/entities/$d/$d.dart';

abstract class ${D}Repo {
  Future<List<$D>> get${D}s();
}
''';
  files['lib/domain/use_case/${d}_use_case.dart'] =
      '''
import 'package:$p/domain/entities/$d/$d.dart';
import 'package:$p/domain/repositories/${d}_repo.dart';

/// Registered in lib/di/register_module.dart; no DI annotation here.
class ${D}UseCase {
  ${D}UseCase(this._repo);

  final ${D}Repo _repo;

  Future<List<$D>> get${D}s() => _repo.get${D}s();
}
''';
  files['lib/data/model/response/$d/${d}_response_model.dart'] =
      '''
import 'package:$p/domain/entities/$d/$d.dart';
import 'package:json_annotation/json_annotation.dart';

part '${d}_response_model.g.dart';

@JsonSerializable()
class ${D}ResponseModel implements $D {
  ${D}ResponseModel({this.id});

  @override
  @JsonKey(name: 'id')
  final String? id;

  factory ${D}ResponseModel.fromJson(Map<String, dynamic> json) =>
      _\$${D}ResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _\$${D}ResponseModelToJson(this);
}
''';
  files['lib/data/datasource/remote/${d}_remote_data_source.dart'] =
      '''
import 'package:$p/data/datasource/remote/api_client.dart';
import 'package:$p/data/model/response/$d/${d}_response_model.dart';
import 'package:injectable/injectable.dart';

abstract class ${D}RemoteDataSource {
  Future<List<${D}ResponseModel>> get${D}s();
}

@LazySingleton(as: ${D}RemoteDataSource)
class ${D}RemoteDataSourceImpl implements ${D}RemoteDataSource {
  ${D}RemoteDataSourceImpl(this._apiHandler);

  final ApiHandler _apiHandler;

  @override
  Future<List<${D}ResponseModel>> get${D}s() async {
    // TODO(scaffold): add the path to UrlEndPoint and use it here.
    final result = await _apiHandler.getList(
      '/${d.replaceAll('_', '-')}s',
      parser: ${D}ResponseModel.fromJson,
    );
    return result.data ?? const [];
  }
}
''';
  files['lib/data/repositories/${d}_repo_impl.dart'] =
      '''
import 'package:$p/data/datasource/remote/${d}_remote_data_source.dart';
import 'package:$p/domain/entities/$d/$d.dart';
import 'package:$p/domain/repositories/${d}_repo.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ${D}Repo)
class ${D}RepoImpl implements ${D}Repo {
  ${D}RepoImpl(this._remote);

  final ${D}RemoteDataSource _remote;

  @override
  Future<List<$D>> get${D}s() => _remote.get${D}s();
}
''';
  return files;
}

/// Manual steps the scaffold prints after writing files. Kept here so the
/// test can check that every step names a real file.
List<String> nextSteps(ScaffoldOptions o) {
  final f = o.feature;
  final d = o.domainName;
  final D = pascal(d);
  return [
    "Add the route in lib/core/common/route.dart: static const String ${camel(f)} = '/${f.replaceAll('_', '-')}'; and SLIPage(name: ${camel(f)}, page: ${camel(f)}ScreenBuilder()).",
    if (o.withData)
      'Register the use case in lib/di/register_module.dart: @lazySingleton ${D}UseCase ${camel(d)}UseCase(${D}Repo repo) => ${D}UseCase(repo);',
    if (o.withData)
      'Move the API path into lib/data/datasource/remote/url_end_point.dart.',
    'Add user-facing text to lib/l10n/arb/app_en.arb and app_vi.arb.',
    'Run derry gen, then derry quality.',
    'Register reusable artifacts with python3 .agents/skills/app-memory/scripts/mem_add.py.',
  ];
}
