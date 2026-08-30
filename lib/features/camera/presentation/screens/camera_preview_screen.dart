import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../controller/camera_controller.dart';
import '../../data/camera_service.dart';

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  late final CameraScreenController controller;

  @override
  void initState() {
    super.initState();

    controller = CameraScreenController(
      CameraService(),
    );

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await controller.initialize();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraController = controller.cameraController;

    if (cameraController == null ||
        !cameraController.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: CameraPreview(cameraController),
    );
  }
}