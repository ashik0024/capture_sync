import 'package:workmanager/workmanager.dart';

import 'upload_worker.dart';

class BackgroundSyncService {

  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );

    print(
      'BackgroundSync: WorkManager initialized',
    );
  }

  static Future<void> registerPeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      'upload-sync-periodic',
      uploadSyncTask,
      frequency: const Duration(
        minutes: 15,
      ),
      constraints: Constraints(
        networkType:
        NetworkType.connected,
      ),
      existingWorkPolicy:
      ExistingPeriodicWorkPolicy.keep,
    );

    print(
      'BackgroundSync: Periodic sync registered',
    );
  }

  static Future<void> registerOneTimeSync() async {
    await Workmanager().registerOneOffTask(
      'upload-sync-one-time',
      uploadSyncTask,
      constraints: Constraints(
        networkType:
        NetworkType.connected,
      ),
      existingWorkPolicy:
      ExistingWorkPolicy.keep,
      backoffPolicy:
      BackoffPolicy.exponential,
      backoffPolicyDelay:
      const Duration(
        seconds: 30,
      ),
    );

    print(
      'BackgroundSync: One-time sync registered',
    );
  }

  static Future<void> cancelPeriodicSync() async {
    await Workmanager().cancelByUniqueName(
      'upload-sync-periodic',
    );

    print(
      'BackgroundSync: Periodic sync cancelled',
    );
  }

  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();

    print(
      'BackgroundSync: All tasks cancelled',
    );
  }
}