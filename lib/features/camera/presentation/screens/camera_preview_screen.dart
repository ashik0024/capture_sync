import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../data/camera_service.dart';
import '../controller/camera_controller.dart';

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key});

  @override
  State<CameraPreviewScreen> createState() =>
      _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  late final CameraScreenController controller;

  double _initialZoom = 1.0;

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

  // -----------------------------
  // PINCH ZOOM
  // -----------------------------

  void _onScaleStart(ScaleStartDetails details) {
    _initialZoom = controller.currentZoom;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final newZoom = _initialZoom * details.scale;

    controller.setZoom(newZoom);

    setState(() {});
  }

  // -----------------------------
  // ZOOM BUTTON
  // -----------------------------

  Widget _buildZoomButton(double zoom) {
    // Don't show button if device doesn't support this zoom.
    if (zoom < controller.minZoom ||
        zoom > controller.maxZoom) {
      return const SizedBox.shrink();
    }

    final isSelected =
        (controller.currentZoom - zoom).abs() < 0.01;

    return GestureDetector(
      onTap: () async {
        await controller.setZoom(zoom);

        if (mounted) {
          setState(() {});
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${zoom}x',
          style: TextStyle(
            color: isSelected
                ? Colors.black
                : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // SWITCH CAMERA
  // -----------------------------

  Future<void> _switchCamera() async {
    if (controller.backCameras.length <= 1) {
      return;
    }

    final nextIndex =
        (controller.selectedCameraIndex + 1) %
            controller.backCameras.length;

    await controller.selectCamera(nextIndex);

    if (mounted) {
      setState(() {});
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

    // Camera is still initializing
    if (cameraController == null ||
        !cameraController.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          // =====================================
          // CAMERA PREVIEW
          // =====================================

          Positioned.fill(
            child: GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              child: CameraPreview(
                cameraController,
              ),
            ),
          ),

          // =====================================
          // TOP CAMERA SWITCH BUTTON
          // =====================================

          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              onPressed: _switchCamera,
              icon: const Icon(
                Icons.flip_camera_ios,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),

          // =====================================
          // ZOOM BUTTONS
          // =====================================

          Positioned(
            left: 0,
            right: 0,
            bottom: 170,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildZoomButton(0.5),
                _buildZoomButton(1.0),
                _buildZoomButton(2.0),
                _buildZoomButton(3.0),
              ],
            ),
          ),

          // =====================================
          // ZOOM SLIDER
          // =====================================

          Positioned(
            left: 25,
            right: 25,
            bottom: 110,
            child: Slider(
              min: controller.minZoom,
              max: controller.maxZoom,
              value: controller.currentZoom.clamp(
                controller.minZoom,
                controller.maxZoom,
              ),
              onChanged: (value) async {
                await controller.setZoom(value);

                if (mounted) {
                  setState(() {});
                }
              },
            ),
          ),

          // =====================================
          // CURRENT ZOOM TEXT
          // =====================================

          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: Center(
              child: Text(
                '${controller.currentZoom.toStringAsFixed(1)}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // =====================================
          // CAPTURE BUTTON
          // =====================================

          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}