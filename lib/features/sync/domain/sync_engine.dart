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

  Future<bool> syncPendingUploads() async {
    final pendingItems =
    await repository.getPendingUploads();

    print(
      'SyncEngine: '
          '${pendingItems.length} items found',
    );

    if (pendingItems.isEmpty) {
      return true;
    }

    bool allSuccessful = true;

    for (final item in pendingItems) {
      final success = await _uploadItem(item);

      if (!success) {
        allSuccessful = false;
      }
    }

    return allSuccessful;
  }

  Future<bool> _uploadItem(
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

        return false;
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

      return true;

    } on SocketException catch (e) {
      print(
        'SyncEngine: No internet ${item.id}',
      );

      print(
        'SyncEngine Error: $e',
      );

      // Keep image in queue.
      await repository.markPending(
        item.id,
      );

      return false;
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

      return false;
    }
  }
}