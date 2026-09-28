import 'dart:async';

import 'package:bloc_cubit_base/core/helper/lib/data_connection_checker.dart';
import 'package:bloc_cubit_base/core/helper/network/network_monitor.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkChecker {
  NetworkChecker({
    ConnectivityMonitor? connectivityMonitor,
    InternetReachabilityMonitor? internetMonitor,
  }) : _connectivityMonitor = connectivityMonitor ?? ConnectivityPlusMonitor(),
       _internetMonitor =
           internetMonitor ?? DataConnectionReachabilityMonitor();

  final ConnectivityMonitor _connectivityMonitor;
  final InternetReachabilityMonitor _internetMonitor;
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<DataConnectionStatus>? _statusSubscription;
  Future<void> _transition = Future<void>.value();
  int _generation = 0;
  bool _disposed = false;

  Stream<bool> get connectionChanges => _connectionController.stream;
  bool? isConnected;

  Future<void> init() async {
    if (_disposed) {
      throw StateError('A disposed NetworkChecker cannot be initialized.');
    }

    final generation = ++_generation;
    await _connectivitySubscription?.cancel();
    await _statusSubscription?.cancel();
    _statusSubscription = null;

    _connectivitySubscription = _connectivityMonitor.changes.listen(
      (results) => _queueConnectivityTransition(results, generation),
    );
  }

  void _queueConnectivityTransition(
    List<ConnectivityResult> results,
    int generation,
  ) {
    _transition = _transition
        .then((_) => _applyConnectivityTransition(results, generation))
        .catchError((Object _, StackTrace _) {});
  }

  Future<void> _applyConnectivityTransition(
    List<ConnectivityResult> results,
    int generation,
  ) async {
    if (_disposed || generation != _generation) {
      return;
    }

    await _statusSubscription?.cancel();
    _statusSubscription = null;
    if (_disposed || generation != _generation) {
      return;
    }

    if (results.contains(ConnectivityResult.none)) {
      _emit(false);
      return;
    }

    _statusSubscription = _internetMonitor.changes.listen((status) {
      if (!_disposed && generation == _generation) {
        _emit(status == DataConnectionStatus.connected);
      }
    });
  }

  void _emit(bool value) {
    if (_disposed || isConnected == value) {
      return;
    }
    isConnected = value;
    _connectionController.add(value);
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;
    _generation++;
    await _connectivitySubscription?.cancel();
    await _statusSubscription?.cancel();
    await _transition;
    await _connectionController.close();
  }
}
