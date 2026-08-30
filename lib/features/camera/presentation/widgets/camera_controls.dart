import 'dart:io';

import 'package:flutter/material.dart';

import '../../../sync/presentation/screens/PendingUploadsScreen.dart';

class CameraControls extends StatelessWidget {
  final List<String> batchPaths;
  final VoidCallback onCapture;
  final VoidCallback onSwitch;
  final VoidCallback? onOpenPending;

  const CameraControls({
    super.key,
    required this.batchPaths,
    required this.onCapture,
    required this.onSwitch,
    this.onOpenPending,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: onOpenPending,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                  color: Colors.black26,
                ),
                clipBehavior: Clip.antiAlias,
                child: batchPaths.isNotEmpty
                    ? Image.file(
                        File(batchPaths.last),
                        fit: BoxFit.cover,
                      )
                    : const SizedBox.shrink(),
              ),
              if (batchPaths.isNotEmpty)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${batchPaths.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        GestureDetector(
          onTap: onCapture,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: const Center(
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ),

        IconButton(
          onPressed: onSwitch,
          icon: const Icon(
            Icons.flip_camera_ios,
            color: Colors.white,
            size: 30,
          ),
        ),
      ],
    );
  }
}
