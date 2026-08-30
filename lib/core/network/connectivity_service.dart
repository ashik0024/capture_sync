import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService({
    Connectivity? connectivity,
  }) : _connectivity =
      connectivity ?? Connectivity();

  Stream<List<ConnectivityResult>>
  get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }

  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult =
      await _connectivity.checkConnectivity();

      if (connectivityResult.contains(
        ConnectivityResult.none,
      )) {
        print('Connectivity: No network');
        return false;
      }

      // Actually test internet access.
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(
        const Duration(seconds: 3),
      );

      final hasInternet = result.isNotEmpty &&
          result.first.rawAddress.isNotEmpty;

      print(
        'Connectivity: Internet = $hasInternet',
      );

      return hasInternet;
    } catch (e) {
      print(
        'Connectivity: Internet check failed: $e',
      );

      return false;
    }
  }

  Future<bool> isConnected() async {
    return hasInternetConnection();
  }
}