import 'package:camera/camera.dart';
import '../../data/camera_service.dart';

class CameraScreenController {
  final CameraService _cameraService;

  CameraController? cameraController;

  CameraScreenController(this._cameraService);

  Future<void> initialize() async {
    final cameras = await _cameraService.getAvailableCameras();

    if (cameras.isEmpty) {
      throw Exception('No camera available');
    }

    CameraDescription? backCamera;

    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.back) {
        backCamera = camera;
        break;
      }
    }

    if (backCamera == null) {
      throw Exception('No back camera available');
    }

    cameraController = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await cameraController!.initialize();
  }

  Future<void> dispose() async {
    await cameraController?.dispose();
  }
}