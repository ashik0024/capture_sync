import 'upload_item.dart';

abstract class SyncRepository {
  Future<void> addUploadItem(
      UploadItem item,
      );

  Future<List<UploadItem>> getPendingUploads();

  Future<void> markUploading(
      String id,
      );

  Future<void> markUploaded(
      String id,
      );

  Future<void> markFailed(
      String id,
      );
}