import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../core/storage/hive_storage.dart';
import '../domain/sync_repository.dart';
import '../domain/upload_item.dart';

class SyncRepositoryImpl implements SyncRepository {
  final HiveStorage storage;

  SyncRepositoryImpl(this.storage);

  Box<Map> get _box => storage.uploadBox;

  @override
  Future<void> addUploadItem(
      UploadItem item,
      ) async {
    await _box.put(
      item.id,
      item.toMap(),
    );
  }

  @override
  Future<List<UploadItem>> getPendingUploads() async {
    final items = <UploadItem>[];

    for (final value in _box.values) {
      final item = UploadItem.fromMap(value);

      if (item.status == UploadStatus.pending ||
          item.status == UploadStatus.failed ||
          item.status == UploadStatus.uploading) {
        items.add(item);
      }
    }

    items.sort(
          (a, b) => a.createdAt.compareTo(b.createdAt),
    );

    return items;
  }

  @override
  Future<void> markUploading(
      String id,
      ) async {
    final existing = _box.get(id);

    if (existing == null) return;

    final item = UploadItem.fromMap(existing);

    final updatedItem = UploadItem(
      id: item.id,
      batchId: item.batchId,
      localPath: item.localPath,
      status: UploadStatus.uploading,
      retryCount: item.retryCount,
      createdAt: item.createdAt,
      uploadedAt: item.uploadedAt,
    );

    await _box.put(
      id,
      updatedItem.toMap(),
    );
  }

  @override
  Future<void> markUploaded(
      String id,
      ) async {
    final existing = _box.get(id);

    if (existing == null) return;

    final item = UploadItem.fromMap(existing);

    final updatedItem = UploadItem(
      id: item.id,
      batchId: item.batchId,
      localPath: item.localPath,
      status: UploadStatus.uploaded,
      retryCount: item.retryCount,
      createdAt: item.createdAt,
      uploadedAt: DateTime.now(),
    );

    await _box.put(
      id,
      updatedItem.toMap(),
    );
  }

  @override
  Future<void> markFailed(
      String id,
      ) async {
    final existing = _box.get(id);

    if (existing == null) return;

    final item = UploadItem.fromMap(existing);

    final updatedItem = UploadItem(
      id: item.id,
      batchId: item.batchId,
      localPath: item.localPath,
      status: UploadStatus.failed,
      retryCount: item.retryCount + 1,
      createdAt: item.createdAt,
      uploadedAt: item.uploadedAt,
    );

    await _box.put(
      id,
      updatedItem.toMap(),
    );
  }

  // -----------------------------------------
  // MARK PENDING
  // -----------------------------------------

  Future<void> markPending(
      String id,
      ) async {
    final existing = _box.get(id);

    if (existing == null) return;

    final item = UploadItem.fromMap(existing);

    final updatedItem = UploadItem(
      id: item.id,
      batchId: item.batchId,
      localPath: item.localPath,
      status: UploadStatus.pending,
      retryCount: item.retryCount,
      createdAt: item.createdAt,
      uploadedAt: item.uploadedAt,
    );

    await _box.put(
      id,
      updatedItem.toMap(),
    );
  }
}