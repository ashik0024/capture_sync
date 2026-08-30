import 'package:capture_sync/features/sync/presentation/screens/upload_palette.dart';
import 'package:flutter/material.dart';



/// Full-width pill button pinned to the bottom of the screen.
/// Shows a spinner while [isSyncing] is true and disables itself.
class SyncActionButton extends StatelessWidget {
  final bool isSyncing;
  final VoidCallback? onPressed;
  final String label;

  const SyncActionButton({
    super.key,
    required this.isSyncing,
    required this.onPressed,
    this.label = 'SYNC PENDING UPLOADS',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isSyncing ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: UploadPalette.blue,
            disabledBackgroundColor: UploadPalette.blue.withOpacity(0.4),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: isSyncing
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}