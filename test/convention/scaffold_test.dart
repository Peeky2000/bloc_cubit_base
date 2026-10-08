import 'package:flutter_test/flutter_test.dart';

import '../../tool/convention/rules.dart';
import '../../tool/scaffold/scaffold.dart';

void main() {
  final variants = <String, ScaffoldOptions>{
    'cubit': const ScaffoldOptions(feature: 'order_list'),
    'cubit with data': const ScaffoldOptions(
      feature: 'order_list',
      withData: true,
      domain: 'order',
    ),
    'bloc': const ScaffoldOptions(feature: 'order_list', stateOwner: 'bloc'),
    'bloc with data': const ScaffoldOptions(
      feature: 'order_list',
      stateOwner: 'bloc',
      withData: true,
    ),
  };

  for (final entry in variants.entries) {
    test('${entry.key} scaffold passes every convention rule', () {
      final files = scaffoldFeature(entry.value);
      final sources = [
        for (final e in files.entries) SourceFile(e.key, e.value),
      ];
      expect(checkAll(sources).map((v) => v.toString()), isEmpty);
    });
  }

  test('cubit scaffold creates the expected files', () {
    final files = scaffoldFeature(variants['cubit with data']!);
    expect(
      files.keys,
      containsAll([
        'lib/presentation/order_list/cubit/order_list_cubit.dart',
        'lib/presentation/order_list/cubit/order_list_state.dart',
        'lib/presentation/order_list/cubit/order_list_effect.dart',
        'lib/presentation/order_list/view/order_list_screen.dart',
        'test/presentation/order_list_cubit_test.dart',
        'lib/domain/entities/order/order.dart',
        'lib/domain/repositories/order_repo.dart',
        'lib/domain/use_case/order_use_case.dart',
        'lib/data/model/response/order/order_response_model.dart',
        'lib/data/datasource/remote/order_remote_data_source.dart',
        'lib/data/repositories/order_repo_impl.dart',
      ]),
    );
  });

  test('invalid names are rejected before anything is generated', () {
    expect(
      () => scaffoldFeature(const ScaffoldOptions(feature: 'OrderList')),
      throwsFormatException,
    );
    expect(
      () => scaffoldFeature(
        const ScaffoldOptions(feature: 'orders', stateOwner: 'redux'),
      ),
      throwsFormatException,
    );
  });

  test('next steps name the route table and DI module', () {
    final steps = nextSteps(variants['cubit with data']!).join('\n');
    expect(steps, contains('lib/core/common/route.dart'));
    expect(steps, contains('lib/di/register_module.dart'));
    expect(steps, contains('derry quality'));
  });
}
