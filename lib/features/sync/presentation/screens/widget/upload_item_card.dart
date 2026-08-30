import 'dart:io';

import 'package:capture_sync/features/sync/presentation/screens/upload_palette.dart';
import 'package:flutter/material.dart';

import '../../../domain/upload_item.dart';


/// A single row in the pending-uploads list: thumbnail, filename,
/// batch id, status text, retry count, and (while uploading) a
/// slim progress bar.
class UploadItemCard extends StatelessWidget {
  final UploadItem item;

  const UploadItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: UploadPalette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: UploadPalette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(path: item.localPath),
              const SizedBox(width: 12),
              Expanded(
                child: _Details(item: item, statusColor: statusColor),
              ),
              if (item.retryCount > 0 && item.status != UploadStatus.uploaded)
                _RetryBadge(count: item.retryCount),
            ],
          ),
          if (item.status == UploadStatus.uploading) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: UploadPalette.cardBorder,
                valueColor: AlwaysStoppedAnimation(UploadPalette.blue),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Color _statusColor(UploadStatus status) {
    switch (status) {
      case UploadStatus.pending:
        return UploadPalette.textSecondary;
      case UploadStatus.uploading:
        return UploadPalette.blue;
      case UploadStatus.uploaded:
        return UploadPalette.green;
      case UploadStatus.failed:
        return UploadPalette.orange;
    }
  }
}

class _Thumbnail extends StatelessWidget {
  final String path;

  const _Thumbnail({required this.path});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 56,
        height: 56,
        color: UploadPalette.cardBorder,
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.insert_drive_file,
            color: UploadPalette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  final UploadItem item;
  final Color statusColor;

  const _Details({required this.item, required this.statusColor});

  String get _statusText {
    switch (item.status) {
      case UploadStatus.pending:
        return 'IN QUEUE';
      case UploadStatus.uploading:
        return 'UPLOADING...';
      case UploadStatus.uploaded:
        return 'SYNCED';
      case UploadStatus.failed:
        return item.retryCount > 0
            ? 'RETRYING... (ATTEMPT ${item.retryCount}/3)'
            : 'WAITING FOR CONNECTION';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.localPath.split('/').last,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: UploadPalette.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Batch ${item.batchId}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: UploadPalette.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _statusText,
          style: TextStyle(
            color: statusColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _RetryBadge extends StatelessWidget {
  final int count;

  const _RetryBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          const Icon(Icons.refresh, size: 13, color: UploadPalette.textSecondary),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: const TextStyle(
              color: UploadPalette.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}