import 'package:flutter_test/flutter_test.dart';

import '../../tool/convention/rules.dart';

List<String> rules(String path, String text) =>
    checkFile(SourceFile(path, text)).map((v) => v.rule).toList();

const _goodCubit = '''
import 'package:injectable/injectable.dart';
part 'order_list_state.dart';
part 'order_list_effect.dart';

@injectable
class OrderListCubit extends BaseCubit<OrderListState> {
  OrderListCubit(this._useCase) : super(OrderListState.initial());
  final OrderUseCase _useCase;
}
''';

const _goodState = '''
part of 'order_list_cubit.dart';

class OrderListState extends BaseAppState<Object> {
  const OrderListState({required super.loading, super.error});
  factory OrderListState.initial() => const OrderListState(loading: LoadingStatus.initial);
  OrderListState copyWith({LoadingStatus? loading, Object? error}) =>
      OrderListState(loading: loading ?? this.loading, error: error);
  @override
  List<Object?> get props => [loading, error];
}
''';

void main() {
  group('presentation', () {
    const cubit = 'lib/presentation/order_list/cubit/order_list_cubit.dart';
    const state = 'lib/presentation/order_list/cubit/order_list_state.dart';

    test('a conventional Cubit and state pass', () {
      expect(rules(cubit, _goodCubit), isEmpty);
      expect(rules(state, _goodState), isEmpty);
    });

    test('a Cubit resolving getIt or missing @injectable fails', () {
      final bad = _goodCubit
          .replaceFirst('@injectable\n', '')
          .replaceFirst(
            'final OrderUseCase _useCase;',
            'final x = getIt<OrderUseCase>();',
          );
      expect(rules(cubit, bad), containsAll(['state-owner', 'state-owner']));
      expect(rules(cubit, bad).length, 2);
    });

    test('a Cubit not extending BaseCubit fails', () {
      final bad = _goodCubit.replaceFirst(
        'extends BaseCubit<OrderListState>',
        'extends Cubit<OrderListState>',
      );
      expect(rules(cubit, bad), ['state-owner']);
    });

    test('a state without copyWith or initial fails', () {
      final bad = _goodState
          .replaceFirst('copyWith(', 'update(')
          .replaceFirst(
            'factory OrderListState.initial(',
            'static OrderListState start(',
          );
      expect(rules(state, bad), ['state-shape', 'state-shape']);
    });

    test('extra files in cubit/ and loose feature files fail', () {
      expect(rules('lib/presentation/order_list/cubit/helpers.dart', ''), [
        'state-files',
      ]);
      expect(rules('lib/presentation/order_list/order_list_screen.dart', ''), [
        'feature-layout',
      ]);
      expect(rules('lib/presentation/order_list/models/a.dart', ''), [
        'feature-layout',
      ]);
    });

    test('effects are a sealed family named after the feature', () {
      const path = 'lib/presentation/order_list/cubit/order_list_effect.dart';
      const good = '''
part of 'order_list_cubit.dart';
sealed class OrderListEffect { const OrderListEffect(); }
final class OrderListShowErrorEffect extends OrderListEffect {}
''';
      expect(rules(path, good), isEmpty);
      expect(
        rules(path, good.replaceFirst('OrderListShowErrorEffect', 'ShowError')),
        ['effect-shape'],
      );
    });

    test('a screen exposes its route builder', () {
      const path = 'lib/presentation/order_list/view/order_list_screen.dart';
      const good = '''
Widget orderListScreenBuilder() => const OrderListScreen();
class OrderListScreen extends StatelessWidget {}
''';
      expect(rules(path, good), isEmpty);
      expect(rules(path, 'class OrderListScreen {}'), ['screen']);
    });

    test('every state owner needs a test file', () {
      final files = [
        const SourceFile(
          'lib/presentation/order_list/cubit/order_list_cubit.dart',
          _goodCubit,
        ),
      ];
      expect(checkFeatureTests(files).single.rule, 'state-test');
      expect(
        checkFeatureTests([
          ...files,
          const SourceFile('test/presentation/order_list_cubit_test.dart', ''),
        ]),
        isEmpty,
      );
    });
  });

  group('domain and data', () {
    test('repository interface and implementation names match', () {
      expect(
        rules(
          'lib/domain/repositories/order_repo.dart',
          'abstract class OrderRepo {}',
        ),
        isEmpty,
      );
      expect(
        rules(
          'lib/domain/repositories/order_repository.dart',
          'abstract class OrderRepository {}',
        ),
        ['repo-name'],
      );
      expect(
        rules(
          'lib/data/repositories/order_repo_impl.dart',
          '@LazySingleton(as: OrderRepo)\nclass OrderRepoImpl implements OrderRepo {}',
        ),
        isEmpty,
      );
      expect(
        rules(
          'lib/data/repositories/order_repo_impl.dart',
          '@lazySingleton\nclass OrderRepoImpl implements OrderRepo {}',
        ),
        ['repo-impl'],
      );
    });

    test('use cases are plain classes registered in the DI module', () {
      const path = 'lib/domain/use_case/order_use_case.dart';
      expect(rules(path, 'class OrderUseCase {}'), isEmpty);
      expect(rules(path, '@lazySingleton\nclass OrderUseCase {}'), [
        'use-case-di',
      ]);
    });

    test('remote data sources are bound by their contract', () {
      const path = 'lib/data/datasource/remote/order_remote_data_source.dart';
      const good = '''
abstract class OrderRemoteDataSource {}
@LazySingleton(as: OrderRemoteDataSource)
class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {}
''';
      expect(rules(path, good), isEmpty);
      expect(rules(path, 'class OrderRemoteDataSource {}'), [
        'data-source',
        'data-source',
      ]);
    });

    test('data models are json_serializable with a part file', () {
      const path = 'lib/data/model/response/order/order_response_model.dart';
      const good = '''
part 'order_response_model.g.dart';
@JsonSerializable()
class OrderResponseModel {}
''';
      expect(rules(path, good), isEmpty);
      expect(rules(path, 'class OrderResponseModel {}'), ['model', 'model']);
    });
  });

  test('print and non snake_case file names are rejected', () {
    expect(rules('lib/core/a.dart', "void f() { print('x'); }"), ['no-print']);
    expect(rules('lib/core/a.dart', "// print('x')\nvoid f() {}"), isEmpty);
    expect(rules('lib/core/a.dart', "debugPrint('x');"), isEmpty);
    expect(rules('lib/core/OrderList.dart', ''), ['file-name']);
  });

  test('the baseline only hides the listed rule for the listed file', () {
    final files = [
      const SourceFile('lib/core/a.dart', "print('x');"),
      const SourceFile('lib/core/b.dart', "print('x');"),
    ];
    final left = checkAll(files, baseline: {'no-print|lib/core/a.dart'});
    expect(left.map((v) => v.path), ['lib/core/b.dart']);
  });
}
