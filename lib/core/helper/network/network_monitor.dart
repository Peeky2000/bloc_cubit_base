import 'dart:async';
import 'dart:io';

import 'package:bloc_cubit_base/core/helper/lib/data_connection_checker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

abstract interface class ConnectivityMonitor {
  Stream<List<ConnectivityResult>> get changes;
}

class ConnectivityPlusMonitor implements ConnectivityMonitor {
  ConnectivityPlusMonitor({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<List<ConnectivityResult>> get changes =>
      _connectivity.onConnectivityChanged;
}

abstract interface class InternetReachabilityMonitor {
  Stream<DataConnectionStatus> get changes;
}

class DataConnectionReachabilityMonitor implements InternetReachabilityMonitor {
  DataConnectionReachabilityMonitor({DataConnectionChecker? checker})
    : _checker = checker ?? DataConnectionChecker() {
    _checker
      ..addresses = _defaultAddresses
      ..checkInterval = const Duration(seconds: 15);
  }

  static final List<AddressCheckOptions> _defaultAddresses = [
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

  final DataConnectionChecker _checker;

  @override
  Stream<DataConnectionStatus> get changes => _checker.onStatusChange;
}
