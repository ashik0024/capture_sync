import 'dart:io';

import '../data/mock_upload_api.dart';
import '../data/sync_repository_impl.dart';
import 'upload_item.dart';

class SyncEngine {
  final SyncRepositoryImpl repository;
  final MockUploadApi api;

  SyncEngine({
    required this.repository,
    required this.api,
  });

  Future<void> syncPendingUploads() async {
    final pendingItems =
    await repository.getPendingUploads();

    print(
      'SyncEngine: ${pendingItems.length} items found',
    );

    for (final item in pendingItems) {
      await _uploadItem(item);
    }
  }

  Future<void> _uploadItem(
      UploadItem item,
      ) async {
    try {
      print(
        'SyncEngine: Uploading ${item.id}',
      );

      final file = File(item.localPath);

      if (!await file.exists()) {
        print(
          'SyncEngine: File missing '
              '${item.localPath}',
        );

        await repository.markFailed(
          item.id,
        );

        return;
      }

      await repository.markUploading(
        item.id,
      );

      await api.uploadImage(
        image: file,
      );

      await repository.markUploaded(
        item.id,
      );

      print(
        'SyncEngine: Upload successful '
            '${item.id}',
      );
    } catch (e) {
      print(
        'SyncEngine: Upload failed '
            '${item.id}',
      );

      print(
        'SyncEngine Error: $e',
      );

      await repository.markFailed(
        item.id,
      );
    }
  }
}