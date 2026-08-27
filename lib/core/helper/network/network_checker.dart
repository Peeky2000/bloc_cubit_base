import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:bloc_cubit_base/core/helper/lib/data_connection_checker.dart';

class NetworkChecker {
  NetworkChecker();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<DataConnectionStatus>? _statusSubscription;
  final StreamController<bool> connectController =
      StreamController<bool>.broadcast();
  final DataConnectionChecker _checker = DataConnectionChecker();
  bool? isConnected;

  Future<void> init() async {
    await _connectivitySubscription?.cancel();
    await _statusSubscription?.cancel();
    _checker.addresses = [
      AddressCheckOptions(
        InternetAddress('1.1.1.1'),
        port: 53,
        timeout: const Duration(seconds: 10),
      ),
      AddressCheckOptions(
        InternetAddress('1.0.0.1'),
        port: 53,
        timeout: const Duration(seconds: 10),
      ),
      AddressCheckOptions(
        InternetAddress('8.8.8.8'),
        port: 53,
        timeout: const Duration(seconds: 10),
      ),
      AddressCheckOptions(
        InternetAddress('8.8.4.4'),
        port: 53,
        timeout: const Duration(seconds: 10),
      ),
      AddressCheckOptions(
        InternetAddress('208.67.222.222'),
        port: 53,
        timeout: const Duration(seconds: 10),
      ),
      AddressCheckOptions(
        InternetAddress('208.67.220.220'),
        port: 53,
        timeout: const Duration(seconds: 10),
      ),
    ];
    _checker.checkInterval = const Duration(seconds: 15);
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) async {
      if (!result.contains(ConnectivityResult.none)) {
        await _statusSubscription?.cancel();
        _statusSubscription = _checker.onStatusChange.listen((status) {
          _emit(status == DataConnectionStatus.connected);
        });
      } else {
        await _statusSubscription?.cancel();
        _statusSubscription = null;
        _emit(false);
      }
    });
  }

  void _emit(bool value) {
    if (isConnected == value) {
      return;
    }
    isConnected = value;
    connectController.add(value);
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _statusSubscription?.cancel();
    await connectController.close();
  }
}
