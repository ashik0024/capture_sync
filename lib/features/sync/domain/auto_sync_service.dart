import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/network/connectivity_service.dart';
import '../data/sync_repository_impl.dart';
import 'sync_engine.dart';

enum SyncEvent {
  offline,
  syncStarted,
  syncCompleted,
  syncFailed,
}

class AutoSyncService {
  final ConnectivityService connectivityService;
  final SyncEngine syncEngine;

  StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;

  final StreamController<SyncEvent>
  _syncEventController =
  StreamController<SyncEvent>.broadcast();

  bool _isSyncing = false;

  AutoSyncService({
    required this.connectivityService,
    required this.syncEngine,
  });

  // ---------------------------------------------------------
  // EVENTS
  // ---------------------------------------------------------

  Stream<SyncEvent> get syncEvents =>
      _syncEventController.stream;

  // ---------------------------------------------------------
  // START
  // ---------------------------------------------------------

  Future<void> start() async {
    print('AutoSync: Service started');

    _connectivitySubscription =
        connectivityService
            .onConnectivityChanged
            .listen(
          _onConnectivityChanged,
        );

    // Check immediately when app starts.
    await sync();
  }

  // ---------------------------------------------------------
  // CONNECTIVITY CHANGED
  // ---------------------------------------------------------

  Future<void> _onConnectivityChanged(
      List<ConnectivityResult> result,
      ) async {
    print(
      'AutoSync: Connectivity changed: $result',
    );

    final hasNetwork =
    !result.contains(
      ConnectivityResult.none,
    );

    if (!hasNetwork) {
      print(
        'AutoSync: Network unavailable',
      );

      _syncEventController.add(
        SyncEvent.offline,
      );

      return;
    }

    print(
      'AutoSync: Network detected',
    );

    // Small delay gives the device time to
    // establish the actual internet connection.
    await Future.delayed(
      const Duration(seconds: 1),
    );

    await sync();
  }

  // ---------------------------------------------------------
  // SYNC
  // ---------------------------------------------------------

  Future<void> sync() async {
    if (_isSyncing) {
      print(
        'AutoSync: Sync already running',
      );

      return;
    }

    final hasInternet =
    await connectivityService
        .hasInternetConnection();

    if (!hasInternet) {
      print(
        'AutoSync: Still offline',
      );

      _syncEventController.add(
        SyncEvent.offline,
      );

      return;
    }

    try {
      _isSyncing = true;

      print(
        'AutoSync: Starting sync...',
      );

      _syncEventController.add(
        SyncEvent.syncStarted,
      );

      final success =
      await syncEngine
          .syncPendingUploads();

      if (success) {
        print(
          'AutoSync: Sync completed',
        );

        _syncEventController.add(
          SyncEvent.syncCompleted,
        );
      } else {
        print(
          'AutoSync: Some uploads failed',
        );

        _syncEventController.add(
          SyncEvent.syncFailed,
        );
      }
    } catch (e) {
      print(
        'AutoSync: Sync error: $e',
      );

      _syncEventController.add(
        SyncEvent.syncFailed,
      );
    } finally {
      _isSyncing = false;
    }
  }

  // ---------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------

  Future<void> dispose() async {
    await _connectivitySubscription
        ?.cancel();

    await _syncEventController.close();
  }
}