import 'package:capture_sync/features/sync/presentation/screens/upload_palette.dart';
import 'package:flutter/material.dart';



/// Top row of the Upload Manager screen: page title + a tappable
/// connectivity/sync-status pill ("STABLE LINK" / "OFFLINE").
class UploadHeaderBar extends StatelessWidget {
  final bool hasInternet;
  final bool isSyncing;
  final VoidCallback? onTapSync;

  const UploadHeaderBar({
    super.key,
    required this.hasInternet,
    required this.isSyncing,
    required this.onTapSync,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = hasInternet ? UploadPalette.green : UploadPalette.red;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Upload Manager',
            style: TextStyle(
              color: UploadPalette.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: isSyncing ? null : onTapSync,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: statusColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSyncing)
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: statusColor,
                      ),
                    )
                  else
                    Icon(Icons.circle, size: 8, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    hasInternet ? 'STABLE LINK' : 'OFFLINE',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}