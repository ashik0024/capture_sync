import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/network/connectivity_service.dart';
import 'sync_engine.dart';

class AutoSyncService {
  final ConnectivityService connectivityService;
  final SyncEngine syncEngine;

  StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;

  bool _isSyncing = false;

  AutoSyncService({
    required this.connectivityService,
    required this.syncEngine,
  });

  Future<void> start() async {
    print('AutoSync: Starting...');

    _connectivitySubscription =
        connectivityService
            .onConnectivityChanged
            .listen(
          _onConnectivityChanged,
        );

    // Check once when application starts.
    await sync();
  }

  Future<void> _onConnectivityChanged(
      List<ConnectivityResult> result,
      ) async {
    print(
      'AutoSync: Connectivity changed: $result',
    );

    if (result.contains(
      ConnectivityResult.none,
    )) {
      print(
        'AutoSync: Device is offline',
      );

      return;
    }

    print(
      'AutoSync: Network detected',
    );

    // Network type exists, now verify actual internet.
    await sync();
  }

  Future<void> sync() async {
    if (_isSyncing) {
      print(
        'AutoSync: Sync already running',
      );

      return;
    }

    final hasInternet =
    await connectivityService.hasInternetConnection();

    if (!hasInternet) {
      print(
        'AutoSync: No internet. '
            'Keeping queue untouched.',
      );

      return;
    }

    try {
      _isSyncing = true;

      print(
        'AutoSync: Starting sync...',
      );

      await syncEngine.syncPendingUploads();

      print(
        'AutoSync: Sync completed',
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
  }
}