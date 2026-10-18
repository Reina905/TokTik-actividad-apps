import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'filtros_faciales_screen.dart';

/// Pantalla "Filtros en vivo": los mismos lentes y bigote de la pantalla
/// "Filtros faciales", pero sobre el video de la cámara en tiempo real.
///
/// La idea de fondo no cambia (InputImage -> procesador -> resultado); lo
/// que cambia es de dónde sale la imagen:
///   foto:  File  -> InputImage.fromFile
///   video: CameraImage (un frame) -> InputImage.fromBytes
/// y que el procesador se llama muchas veces por segundo, así que hay que
/// descartar frames mientras ML Kit sigue ocupado con el anterior.
class FiltrosEnVivoScreen extends StatefulWidget {
  const FiltrosEnVivoScreen({super.key});

  @override
  State<FiltrosEnVivoScreen> createState() => _FiltrosEnVivoScreenState();
}

class _FiltrosEnVivoScreenState extends State<FiltrosEnVivoScreen> {
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  CameraController? _controller;

  ui.Image? _glassesImage;
  ui.Image? _mustacheImage;
  bool _showGlasses = true;
  bool _showMustache = true;

  List<Face> _faces = [];
  // Tamaño del frame tal como lo "ve" ML Kit (ya rotado a vertical): las
  // coordenadas de los landmarks vienen en este sistema de referencia.
  Size? _frameSize;
  bool _isProcessing = false;
  String? _error;

  // En video conviene el modo "fast": se procesan muchos frames por
  // segundo y la precisión extra de "accurate" no compensa el retraso.
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableLandmarks: true,
    ),
  );

  @override
  void initState() {
    super.initState();
    // Se fija la orientación vertical: así la rotación del frame es
    // siempre la del sensor y no hay que recalcularla al girar el teléfono.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _loadOverlayAssets();
    _initCameras();
  }

  Future<void> _loadOverlayAssets() async {
    final glasses = await cargarImagenDeAsset('assets/filtros/glasses.png');
    final mustache = await cargarImagenDeAsset('assets/filtros/bigote.png');
    if (!mounted) return;
    setState(() {
      _glassesImage = glasses;
      _mustacheImage = mustache;
    });
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'Este dispositivo no tiene cámara.');
        return;
      }
      // Empezamos con la cámara frontal, que es la natural para un filtro.
      final front = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _cameraIndex = front >= 0 ? front : 0;
      await _startCamera();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo abrir la cámara: $e');
    }
  }

  Future<void> _startCamera() async {
    final controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
      // ML Kit acepta NV21 en Android y BGRA8888 en iOS cuando la imagen
      // llega como bytes crudos.
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

  @override
  void dispose() {
    _stopCamera();
    _faceDetector.close();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  /// Se llama por CADA frame de la cámara (~30 por segundo).
  Future<void> _processFrame(CameraImage image) async {
    // Si ML Kit sigue procesando el frame anterior, este se descarta.
    // Sin esta bandera se acumularían cientos de llamadas pendientes.
    if (_isProcessing) return;
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
    } catch (e) {
      debugPrint('Error al detectar rostros: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Convierte un frame de la cámara en un InputImage. A diferencia de
  /// InputImage.fromFile, aquí hay que decirle a ML Kit el tamaño, el
  /// formato de los bytes y cuánto está rotado el sensor.
  InputImage? _toInputImage(CameraImage image) {
    final camera = _cameras[_cameraIndex];
    // Con la pantalla fija en vertical, la rotación es la del sensor
    // (normalmente 90° en la trasera y 270° en la frontal).
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

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtros en vivo'),
        actions: [
          if (_cameras.length > 1)
            IconButton(
              tooltip: 'Cambiar cámara',
              icon: const Icon(Icons.cameraswitch_outlined),
              onPressed: ready ? _switchCamera : null,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, textAlign: TextAlign.center),
                    )
                  : !ready
                      ? const CircularProgressIndicator()
                      : AspectRatio(
                          // previewSize viene en horizontal; en vertical
                          // se invierte la proporción.
                          aspectRatio: 1 / controller.value.aspectRatio,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CameraPreview(controller),
                              if (_frameSize != null)
                                CustomPaint(
                                  painter: FiltrosEnVivoPainter(
                                    faces: _faces,
                                    frameSize: _frameSize!,
                                    mirror: controller.description
                                            .lensDirection ==
                                        CameraLensDirection.front,
                                    glasses:
                                        _showGlasses ? _glassesImage : null,
                                    mustache:
                                        _showMustache ? _mustacheImage : null,
                                  ),
                                ),
                            ],
                          ),
                        ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              children: [
                Text(
                  '${_faces.length} rostro(s) en el frame actual',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Lentes'),
                  value: _showGlasses,
                  onChanged: (v) => setState(() => _showGlasses = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bigote'),
                  value: _showMustache,
                  onChanged: (v) => setState(() => _showMustache = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dibuja los filtros encima del CameraPreview. No dibuja el video (de eso
/// se encarga CameraPreview); solo transforma el canvas para que las
/// coordenadas de ML Kit (píxeles del frame) caigan sobre la vista previa.
class FiltrosEnVivoPainter extends CustomPainter {
  final List<Face> faces;
  final Size frameSize;
  final bool mirror;
  final ui.Image? glasses;
  final ui.Image? mustache;

  FiltrosEnVivoPainter({
    required this.faces,
    required this.frameSize,
    required this.mirror,
    required this.glasses,
    required this.mustache,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // La cámara frontal se muestra como espejo (como cualquier app de
    // selfies), pero ML Kit entrega coordenadas sin espejar: se refleja
    // el canvas en X para que coincidan.
    if (mirror) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    // Mismo truco que en la pantalla de fotos: escalar el canvas una vez
    // y luego dibujar directamente con las coordenadas de ML Kit.
    canvas.scale(size.width / frameSize.width, size.height / frameSize.height);

    for (final face in faces) {
      pintarFiltrosEnRostro(
        canvas: canvas,
        face: face,
        glasses: glasses,
        mustache: mustache,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FiltrosEnVivoPainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.frameSize != frameSize ||
        oldDelegate.mirror != mirror ||
        oldDelegate.glasses != glasses ||
        oldDelegate.mustache != mustache;
  }
}
