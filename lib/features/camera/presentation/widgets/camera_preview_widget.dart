import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController cameraController;
  final GestureTapUpCallback? onTapUp;
  final Function(ScaleStartDetails)? onScaleStart;
  final Function(ScaleUpdateDetails)? onScaleUpdate;

  const CameraPreviewWidget({
    super.key,
    required this.cameraController,
    this.onTapUp,
    this.onScaleStart,
    this.onScaleUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: onTapUp,
      onScaleStart: onScaleStart,
      onScaleUpdate: onScaleUpdate,
      child: CameraPreview(cameraController),
    );
  }
}
