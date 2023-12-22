import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:delivery_go/core/helper/lib/data_connection_checker.dart';

class NetworkChecker {
  NetworkChecker();

  StreamSubscription? _subscription;
  StreamSubscription? _subscriptionDataChecker;
  StreamController<bool> connectController = StreamController<bool>.broadcast();
  final DataConnectionChecker _checker = DataConnectionChecker();
  bool? isConnected;

  Future<void> init() async {
    connectController.stream.listen((event) {
      isConnected = event;
    });
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
    // ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
    // if (connectivityResult == ConnectivityResult.none) {
    //   if (isConnected && !_isCheckFirst) {
    //     connectController.sink.add(false);
    //   }
    // } else {
    //   if (!_isCheckFirst) {
    //     connectController.sink.add(await _checker.hasConnection);
    //   }
    // }
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        _subscriptionDataChecker = _checker.onStatusChange.listen((status) {
          bool isConnectedData = status == DataConnectionStatus.connected;
          if (isConnected != null && isConnected != isConnectedData) {
            connectController.sink.add(isConnectedData);
          } else {
            isConnected ??= isConnectedData;
          }
        });
      } else {
        connectController.sink.add(false);
        _subscriptionDataChecker?.cancel();
      }
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
