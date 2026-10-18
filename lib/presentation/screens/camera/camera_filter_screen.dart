import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:toktok/presentation/screens/upload/upload_screen.dart';
import 'package:toktok/presentation/widgets/filters/face_filter_utils.dart';
import 'package:toktok/presentation/widgets/filters/filter_selector.dart';
import 'package:toktok/presentation/widgets/filters/live_filter_painter.dart';

class CameraFilterScreen extends StatefulWidget {
  const CameraFilterScreen({super.key});

  @override
  State<CameraFilterScreen> createState() => _CameraFilterScreenState();
}

class _CameraFilterScreenState extends State<CameraFilterScreen> {
  // ── Cámara ────────────────────────────────────────────────────────────────
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  CameraController? _controller;
  bool _isRecording = false;

  // ── ML Kit ────────────────────────────────────────────────────────────────
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableLandmarks: true,
    ),
  );
  List<Face> _faces = [];
  Size? _frameSize;
  bool _isProcessing = false;

  // ── Filtros ───────────────────────────────────────────────────────────────
  FaceFilterType _selectedFilter = FaceFilterType.none;
  FaceFilterAssets _filterAssets = FaceFilterAssets.empty();

  String? _error;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initCameras();
  }

  @override
  void dispose() {
    _stopCamera();
    _faceDetector.close();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  // ── Cámara ────────────────────────────────────────────────────────────────

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'No se encontró ninguna cámara.');
        return;
      }
      final front = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _cameraIndex = front >= 0 ? front : 0;
      await _startCamera();
    } catch (e) {
      setState(() => _error = 'No se pudo abrir la cámara: $e');
    }
  }

  Future<void> _startCamera() async {
    final controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.medium,
      enableAudio: true,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _controller = controller;
    await controller.initialize();
    if (!mounted) return;
    await controller.startImageStream(_processFrame);
    setState(() {});
  }

  Future<void> _stopCamera() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
    await controller.dispose();
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    await _stopCamera();
    setState(() {
      _faces = [];
      _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    });
    await _startCamera();
  }

  // ── Grabación ─────────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
    await controller.startVideoRecording();
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    final controller = _controller;
    if (controller == null) return;
    final file = await controller.stopVideoRecording();

    // Capturar el estado del filtro justo antes de navegar para
    // que UploadScreen pueda mostrar el overlay del filtro en el video.
    final filterAtStop = _selectedFilter;
    final assetsAtStop = _filterAssets;
    final facesAtStop = List<Face>.from(_faces);

    setState(() => _isRecording = false);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => UploadScreen(
          file: File(file.path),
          isVideo: true,
          initialFilter: filterAtStop,
          initialFilterAssets: assetsAtStop,
          initialFaces: facesAtStop,
        ),
      ),
    );
  }

  // ── ML Kit — procesamiento de frames ─────────────────────────────────────

  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessing || _selectedFilter == FaceFilterType.none) return;
    final inputImage = _toInputImage(image);
    if (inputImage == null) return;

    _isProcessing = true;
    try {
      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted) return;
      final rotation = inputImage.metadata!.rotation;
      final rotated = rotation == InputImageRotation.rotation90deg ||
          rotation == InputImageRotation.rotation270deg;
      setState(() {
        _faces = faces;
        _frameSize = rotated
            ? Size(image.height.toDouble(), image.width.toDouble())
            : Size(image.width.toDouble(), image.height.toDouble());
      });
    } catch (_) {
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final camera = _cameras[_cameraIndex];
    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (rotation == null || format == null) return null;
    if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
    if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;
    if (image.planes.length != 1) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // ── Filtros ───────────────────────────────────────────────────────────────

  Future<void> _onFilterSelected(FaceFilterType type) async {
    final assets = await loadFilterAssets(type);
    if (!mounted) return;
    setState(() {
      _selectedFilter = type;
      _filterAssets = assets;
      if (type == FaceFilterType.none) _faces = [];
    });
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Barra superior ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (_cameras.length > 1)
                    IconButton(
                      icon: const Icon(Icons.cameraswitch_outlined,
                          color: Colors.white),
                      onPressed: ready && !_isRecording ? _switchCamera : null,
                    ),
                ],
              ),
            ),

            // ── Preview de cámara ───────────────────────────────────────────
            Expanded(
              child: Center(
                child: _error != null
                    ? Text(_error!,
                        style: const TextStyle(color: Colors.white))
                    : !ready
                        ? const CircularProgressIndicator()
                        : AspectRatio(
                            aspectRatio: 1 / controller.value.aspectRatio,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CameraPreview(controller),
                                if (_frameSize != null &&
                                    _selectedFilter != FaceFilterType.none)
                                  CustomPaint(
                                    painter: LiveFilterPainter(
                                      faces: _faces,
                                      frameSize: _frameSize!,
                                      mirror: controller.description
                                              .lensDirection ==
                                          CameraLensDirection.front,
                                      filterAssets: _filterAssets,
                                      filterType: _selectedFilter,
                                    ),
                                  ),
                              ],
                            ),
                          ),
              ),
            ),

            // ── Selector de filtro ──────────────────────────────────────────
            FilterSelector(
              selected: _selectedFilter,
              onSelect: _onFilterSelected,
            ),

            // ── Botón de grabación ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: GestureDetector(
                onTap: ready
                    ? (_isRecording ? _stopRecording : _startRecording)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording
                        ? const Color(0xFFEE1D52)
                        : Colors.white,
                    border: Border.all(
                      color: _isRecording ? Colors.white : Colors.white54,
                      width: 4,
                    ),
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.fiber_manual_record,
                    color: _isRecording ? Colors.white : const Color(0xFFEE1D52),
                    size: 32,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
