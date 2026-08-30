import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/network/connectivity_service.dart';
import 'core/storage/hive_storage.dart';
import 'features/sync/data/mock_upload_api.dart';
import 'features/sync/data/sync_repository_impl.dart';
import 'features/sync/domain/auto_sync_service.dart';
import 'features/sync/domain/sync_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hiveStorage = HiveStorage();

  await hiveStorage.init();

  final repository = SyncRepositoryImpl(
    hiveStorage,
  );

  // -----------------------------------------
  // CONNECTIVITY
  // -----------------------------------------

  final connectivityService =
  ConnectivityService();

  // -----------------------------------------
  // MOCK API
  // -----------------------------------------

  final mockApi = MockUploadApi(
    connectivityService: connectivityService,
    shouldFail: false,
  );

  // -----------------------------------------
  // SYNC ENGINE
  // -----------------------------------------

  final syncEngine = SyncEngine(
    repository: repository,
    api: mockApi,
  );

  // -----------------------------------------
  // AUTO SYNC
  // -----------------------------------------

  final autoSyncService = AutoSyncService(
    connectivityService: connectivityService,
    syncEngine: syncEngine,
  );

  await autoSyncService.start();

  runApp(
    const CaptureSyncApp(),
  );
}