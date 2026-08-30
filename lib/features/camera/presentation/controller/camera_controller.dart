import 'package:camera/camera.dart';
import '../../data/camera_service.dart';

class CameraScreenController {
  final CameraService _cameraService;

  CameraController? cameraController;

  double minZoom = 1.0;
  double maxZoom = 1.0;
  double currentZoom = 1.0;

  List<CameraDescription> backCameras = [];
  int selectedCameraIndex = 0;

  CameraScreenController(this._cameraService);

  Future<void> initialize() async {
    final cameras = await _cameraService.getAvailableCameras();

    backCameras = cameras
        .where(
          (camera) => camera.lensDirection == CameraLensDirection.back,
    )
        .toList();

    if (backCameras.isEmpty) {
      throw Exception('No back camera available');
    }

    await _initializeCamera(backCameras[selectedCameraIndex]);
  }

  Future<void> _initializeCamera(
      CameraDescription camera,
      ) async {
    await cameraController?.dispose();

    cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await cameraController!.initialize();

    minZoom = await cameraController!.getMinZoomLevel();
    maxZoom = await cameraController!.getMaxZoomLevel();

    currentZoom = 1.0;

    await cameraController!.setZoomLevel(currentZoom);
  }

  Future<void> setZoom(double zoom) async {
    if (cameraController == null) return;

    final value = zoom.clamp(minZoom, maxZoom);

    currentZoom = value;

    await cameraController!.setZoomLevel(value);
  }

  Future<void> selectCamera(int index) async {
    if (index < 0 || index >= backCameras.length) {
      return;
    }

    selectedCameraIndex = index;

    await _initializeCamera(
      backCameras[index],
    );
  }

  Future<void> dispose() async {
    await cameraController?.dispose();
  }
}