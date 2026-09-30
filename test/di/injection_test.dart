import 'package:bloc_cubit_base/core/app/app_config.dart';
import 'package:bloc_cubit_base/di/injection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() => getIt.reset());
  tearDown(() => getIt.reset());

  test(
    'reset disposes the previous graph before registering a new one',
    () async {
      final disposedIds = <int>[];

      Future<GetIt> initializeProbe(GetIt container, int id) async {
        container.registerSingleton<_Probe>(
          _Probe(id),
          dispose: (probe) => disposedIds.add(probe.id),
        );
        return container;
      }

      await configureDependencies(
        AppConfig.forEnvironment(AppEnvironment.development),
        initializeGraph: (container) => initializeProbe(container, 1),
      );
      expect(getIt<_Probe>().id, 1);

      await configureDependencies(
        AppConfig.forEnvironment(AppEnvironment.staging),
        reset: true,
        initializeGraph: (container) => initializeProbe(container, 2),
      );

      expect(disposedIds, [1]);
      expect(getIt<_Probe>().id, 2);
    },
  );

  test(
    'returns the same composition root populated by the initializer',
    () async {
      final result = await configureDependencies(
        AppConfig.forEnvironment(AppEnvironment.development),
        initializeGraph: (container) {
          container.registerFactory<_Probe>(() => const _Probe(7));
          return container;
        },
      );

      expect(result, same(getIt));
      expect(result<_Probe>().id, 7);
    },
  );
}

class _Probe {
  const _Probe(this.id);

  final int id;
}
