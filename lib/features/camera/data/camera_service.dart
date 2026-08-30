import 'package:camera/camera.dart';

class CameraService {
  List<CameraDescription> _cameras = [];

  Future<List<CameraDescription>> getAvailableCameras() async {
    _cameras = await availableCameras();

    return _cameras;
  }

  CameraDescription? getBackCamera() {
    for (final camera in _cameras) {
      if (camera.lensDirection == CameraLensDirection.back) {
        return camera;
      }
    }

    return null;
  }
}