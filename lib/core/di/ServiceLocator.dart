import '../../features/sync/data/mock_upload_api.dart';
import '../../features/sync/data/sync_repository_impl.dart';
import '../../features/sync/domain/auto_sync_service.dart';
import '../../features/sync/domain/sync_engine.dart';
import '../network/connectivity_service.dart';
import '../storage/hive_storage.dart';

class ServiceLocator {
  static late final AutoSyncService autoSyncService;

  static Future<void> init() async {
    final storage = HiveStorage();

    final connectivityService =
    ConnectivityService();

    final repository =
    SyncRepositoryImpl(storage);

    final mockApi =
    MockUploadApi(
      connectivityService: connectivityService,
      shouldFail: false,
    );

    final syncEngine =
    SyncEngine(
      repository: repository,
      api: mockApi,
    );

    autoSyncService =
        AutoSyncService(
          connectivityService: connectivityService,
          syncEngine: syncEngine,
        );

    await autoSyncService.start();
  }
}