import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/storage/file_storage.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/worker/background_sync_service.dart';
import '../../../sync/data/sync_repository_impl.dart';
import '../../../sync/domain/upload_item.dart';
import '../../../sync/presentation/screens/PendingUploadsScreen.dart';
import '../../data/camera_service.dart';
import '../controller/camera_controller.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/camera_controls.dart';
import '../widgets/tap_focus_indicator.dart';

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  late final CameraScreenController controller;

  double _initialZoom = 1.0;
  Offset? _focusPosition;
  bool _flashOn = false;
  bool _showCaptureFlash = false;

  final FileStorage _fileStorage = FileStorage();
  final Uuid _uuid = const Uuid();
  late final String batchId;
  final HiveStorage _hiveStorage = HiveStorage();

  late final SyncRepositoryImpl _syncRepository;

  // Tracks images captured into the current batch, for the thumbnail + counter.
  final List<String> _batchPaths = [];

  @override
  void initState() {
    super.initState();

    batchId = const Uuid().v4();

    _syncRepository = SyncRepositoryImpl(_hiveStorage);

    controller = CameraScreenController(CameraService());

    _initializeCamera();
  }

  Future<void> _handleTapToFocus(
      TapUpDetails details,
      BuildContext context,
      ) async {
    final screenSize = MediaQuery.of(context).size;
    final tapPosition = details.localPosition;

    final focusPoint = Offset(
      tapPosition.dx / screenSize.width,
      tapPosition.dy / screenSize.height,
    );

    await controller.setFocusPoint(focusPoint);

    setState(() => _focusPosition = tapPosition);

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _focusPosition = null);
    }
  }

  Future<void> _initializeCamera() async {
    try {
      await controller.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
    }
  }

  // -----------------------------
  // FLASH
  // -----------------------------
  Future<void> _toggleFlash() async {
    final cam = controller.cameraController;
    if (cam == null) return;

    try {
      final newValue = !_flashOn;
      await cam.setFlashMode(newValue ? FlashMode.torch : FlashMode.off);
      setState(() => _flashOn = newValue);
    } catch (e) {
      debugPrint('Toggling flash failed: $e');
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
  // ZOOM PRESET BUTTON
  // -----------------------------
  Widget _buildZoomButton(double zoom) {
    if (zoom < controller.minZoom || zoom > controller.maxZoom) {
      return const SizedBox.shrink();
    }

    final isSelected = (controller.currentZoom - zoom).abs() < 0.01;

    return GestureDetector(
      onTap: () async {
        await controller.setZoom(zoom);
        if (mounted) setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.black45,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          zoom == zoom.roundToDouble() ? '${zoom.toInt()}x' : '${zoom}x',
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // SWITCH CAMERA
  // -----------------------------
  Future<void> _switchCamera() async {
    if (controller.backCameras.length <= 1) return;

    final nextIndex =
        (controller.selectedCameraIndex + 1) % controller.backCameras.length;

    await controller.selectCamera(nextIndex);
    if (mounted) setState(() {});
  }

  // -----------------------------
  // CAPTURE
  // -----------------------------
  Future<void> _captureImage() async {
    final image = await controller.takePicture();
    if (image == null) return;

    try {
      final imageId = const Uuid().v4();
      final fileName = '${batchId}_$imageId.jpg';

      final savedPath = await _fileStorage.saveImage(image.path, fileName);

      final uploadItem = UploadItem(
        id: imageId,
        batchId: batchId,
        localPath: savedPath,
        status: UploadStatus.pending,
        retryCount: 0,
        createdAt: DateTime.now(),
      );

      await _syncRepository.addUploadItem(uploadItem);
      await BackgroundSyncService.registerOneTimeSync();

      // tactile + audible feedback
      try {
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}

      // quick white flash overlay to indicate capture
      if (mounted) setState(() => _showCaptureFlash = true);
      await Future.delayed(const Duration(milliseconds: 180));
      if (mounted) setState(() => _showCaptureFlash = false);

      debugPrint('Image saved and queued');
      debugPrint('Path: $savedPath');
      debugPrint('Status: ${uploadItem.status.name}');

      if (!mounted) return;

      setState(() => _batchPaths.add(savedPath));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image added to upload queue')),
      );
    } catch (e) {
      debugPrint('Capture processing failed: $e');
    }
  }

  Future<void> _uploadBatch() async {
    if (_batchPaths.isEmpty) return;
    await BackgroundSyncService.registerOneTimeSync();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Uploading batch of ${_batchPaths.length}')),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraController = controller.cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
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
            child: CameraPreviewWidget(
              cameraController: cameraController,
              onTapUp: (details) => _handleTapToFocus(details, context),
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
            ),
          ),

          // Subtle top/bottom vignette so white icons/text stay readable
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.45),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.55),
                    ],
                    stops: const [0.0, 0.18, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // quick white flash when capturing
          if (_showCaptureFlash)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _showCaptureFlash ? 0.9 : 0.0,
                  duration: const Duration(milliseconds: 120),
                  child: Container(color: Colors.white),
                ),
              ),
            ),

          // =====================================
          // TOP BAR: close / flash / settings
          // =====================================
          Positioned(
            top: 44,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _toggleFlash,
                      icon: Icon(
                        _flashOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: wire up capture settings sheet
                      },
                      icon: const Icon(Icons.settings, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // =====================================
          // MODE LABEL
          // =====================================
          const Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'VISUAL',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

          // =====================================
          // VERTICAL ZOOM SLIDER (right edge)
          // =====================================
          Positioned(
            right: 4,
            top: 170,
            bottom: 260,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${controller.maxZoom.toStringAsFixed(0)}x',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Expanded(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white30,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        min: controller.minZoom,
                        max: controller.maxZoom,
                        value: controller.currentZoom.clamp(
                          controller.minZoom,
                          controller.maxZoom,
                        ),
                        onChanged: (value) async {
                          await controller.setZoom(value);
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
                const Text(
                  '1x',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),

          // =====================================
          // ZOOM PRESET BUTTONS
          // =====================================
          Positioned(
            left: 0,
            right: 0,
            bottom: 178,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildZoomButton(0.5),
                _buildZoomButton(1.0),
                _buildZoomButton(2.0),
              ],
            ),
          ),

          // =====================================
          // THUMBNAIL / CAPTURE / SWITCH CAMERA
          // =====================================
          Positioned(
            left: 0,
            right: 0,
            bottom: 96,
            child: CameraControls(
              batchPaths: _batchPaths,
              onCapture: _captureImage,
              onSwitch: _switchCamera,
              onOpenPending: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PendingUploadsScreen(),
                  ),
                );
              },
            ),
          ),

          // =====================================
          // LIVE VIEW LABEL
          // =====================================
          const Positioned(
            left: 0,
            right: 0,
            bottom: 68,
            child: Center(
              child: Text(
                'LIVE VIEW',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          // =====================================
          // UPLOAD BATCH BUTTON (full width)
          // =====================================
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ElevatedButton(
                  onPressed: _batchPaths.isEmpty ? null : _uploadBatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    disabledBackgroundColor: Colors.blue.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.upload, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'UPLOAD BATCH (${_batchPaths.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // =====================================
          // TAP-TO-FOCUS INDICATOR
          // =====================================
          if (_focusPosition != null)
            Positioned(
              left: _focusPosition!.dx - 35,
              top: _focusPosition!.dy - 35,
              child: TapToFocusIndicator(position: _focusPosition!),
            ),
        ],
      ),
    );
  }
}