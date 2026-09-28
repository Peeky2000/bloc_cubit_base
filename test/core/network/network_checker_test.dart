import 'dart:async';

import 'package:bloc_cubit_base/core/helper/lib/data_connection_checker.dart';
import 'package:bloc_cubit_base/core/helper/network/network_checker.dart';
import 'package:bloc_cubit_base/core/helper/network/network_monitor.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkChecker lifecycle', () {
    test('repeated init keeps one connectivity subscription', () async {
      final connectivity = _ConnectivityMonitorFake();
      final internet = _InternetMonitorFake();
      final checker = NetworkChecker(
        connectivityMonitor: connectivity,
        internetMonitor: internet,
      );

      await checker.init();
      await checker.init();
      await checker.init();

      expect(connectivity.activeListeners, 1);
      expect(connectivity.listenCount, 3);
      expect(connectivity.cancelCount, 2);

      await checker.dispose();
      expect(connectivity.activeListeners, 0);
      expect(connectivity.cancelCount, 3);
    });

    test(
      'switches reachability subscription and suppresses duplicates',
      () async {
        final connectivity = _ConnectivityMonitorFake();
        final internet = _InternetMonitorFake();
        final checker = NetworkChecker(
          connectivityMonitor: connectivity,
          internetMonitor: internet,
        );
        final changes = <bool>[];
        final subscription = checker.connectionChanges.listen(changes.add);
        addTearDown(subscription.cancel);
        addTearDown(checker.dispose);
        await checker.init();

        connectivity.emit([ConnectivityResult.wifi]);
        await pumpEventQueue();
        expect(internet.activeListeners, 1);

        internet
          ..emit(DataConnectionStatus.connected)
          ..emit(DataConnectionStatus.connected)
          ..emit(DataConnectionStatus.disconnected);
        await pumpEventQueue();
        expect(changes, [true, false]);
        expect(checker.isConnected, isFalse);

        connectivity.emit([ConnectivityResult.none]);
        await pumpEventQueue();
        expect(internet.activeListeners, 0);
        expect(changes, [true, false]);

        connectivity.emit([ConnectivityResult.mobile]);
        await pumpEventQueue();
        internet.emit(DataConnectionStatus.connected);
        await pumpEventQueue();
        expect(changes, [true, false, true]);
      },
    );

    test('dispose is idempotent and prevents reinitialization', () async {
      final connectivity = _ConnectivityMonitorFake();
      final internet = _InternetMonitorFake();
      final checker = NetworkChecker(
        connectivityMonitor: connectivity,
        internetMonitor: internet,
      );
      await checker.init();

      await checker.dispose();
      await checker.dispose();

      expect(connectivity.activeListeners, 0);
      await expectLater(checker.init(), throwsStateError);
    });
  });
}

class _ConnectivityMonitorFake implements ConnectivityMonitor {
  _ConnectivityMonitorFake() {
    _controller = StreamController<List<ConnectivityResult>>.broadcast(
      sync: true,
      onListen: () {
        activeListeners++;
        listenCount++;
      },
      onCancel: () {
        activeListeners--;
        cancelCount++;
      },
    );
  }

  late final StreamController<List<ConnectivityResult>> _controller;
  int activeListeners = 0;
  int listenCount = 0;
  int cancelCount = 0;

  @override
  Stream<List<ConnectivityResult>> get changes => _controller.stream;

  void emit(List<ConnectivityResult> results) => _controller.add(results);
}

class _InternetMonitorFake implements InternetReachabilityMonitor {
  _InternetMonitorFake() {
    _controller = StreamController<DataConnectionStatus>.broadcast(
      sync: true,
      onListen: () => activeListeners++,
      onCancel: () => activeListeners--,
    );
  }

  late final StreamController<DataConnectionStatus> _controller;
  int activeListeners = 0;

  @override
  Stream<DataConnectionStatus> get changes => _controller.stream;

  void emit(DataConnectionStatus status) => _controller.add(status);
}
