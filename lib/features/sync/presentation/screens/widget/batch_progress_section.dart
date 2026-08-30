import 'package:capture_sync/features/sync/presentation/screens/upload_palette.dart';
import 'package:flutter/material.dart';



/// "BATCH SYNC PROGRESS" block: label, percentage, progress bar,
/// and an "x / y items synced" caption.
class BatchProgressSection extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final int uploadedCount;
  final int totalCount;

  const BatchProgressSection({
    super.key,
    required this.progress,
    required this.uploadedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BATCH SYNC PROGRESS',
                style: TextStyle(
                  color: UploadPalette.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: UploadPalette.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: UploadPalette.cardBorder,
              valueColor: const AlwaysStoppedAnimation(UploadPalette.blue),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$uploadedCount / $totalCount items synced',
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

/// Small uppercase section label, e.g. "PENDING UPLOADS (8)".
class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: UploadPalette.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}