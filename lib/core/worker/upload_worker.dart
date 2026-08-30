import 'package:workmanager/workmanager.dart';

import '../../features/sync/data/mock_upload_api.dart';
import '../../features/sync/data/sync_repository_impl.dart';
import '../../features/sync/domain/sync_engine.dart';
import '../network/connectivity_service.dart';
import '../storage/hive_storage.dart';

const String uploadSyncTask = 'upload_sync_task';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask(
        (
        task,
        inputData,
        ) async {
      print(
        'WorkManager: Task started: $task',
      );

      try {
        // -----------------------------------------
        // INITIALIZE HIVE
        // -----------------------------------------

        final storage = HiveStorage();

        await storage.init();

        // -----------------------------------------
        // CONNECTIVITY
        // -----------------------------------------

        final connectivityService =
        ConnectivityService();

        final hasInternet =
        await connectivityService
            .hasInternetConnection();

        if (!hasInternet) {
          print(
            'WorkManager: No internet connection',
          );

          // Returning false tells WorkManager
          // that this execution did not complete.
          //
          // The upload remains in Hive.
          return false;
        }

        // -----------------------------------------
        // REPOSITORY
        // -----------------------------------------

        final repository =
        SyncRepositoryImpl(
          storage,
        );

        // -----------------------------------------
        // API
        // -----------------------------------------

        final api = MockUploadApi(
          connectivityService:
          connectivityService,
          shouldFail: false,
        );

        // -----------------------------------------
        // SYNC ENGINE
        // -----------------------------------------

        final syncEngine = SyncEngine(
          repository: repository,
          api: api,
        );

        // -----------------------------------------
        // SYNC
        // -----------------------------------------

        final success =
        await syncEngine
            .syncPendingUploads();

        if (success) {
          print(
            'WorkManager: Upload sync completed',
          );
        } else {
          print(
            'WorkManager: Some uploads failed',
          );
        }

        return success;
      } catch (e, stackTrace) {
        print(
          'WorkManager: Error: $e',
        );

        print(
          stackTrace,
        );

        return false;
      }
    },
  );
}