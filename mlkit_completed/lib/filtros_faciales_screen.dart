import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Pantalla "Filtros faciales": una aplicación concreta de los landmarks
/// que devuelve FaceDetector cuando enableLandmarks es true. El guion de
/// la Clase 24 presenta estas opciones solo "a nivel de panorama" (se
/// profundizan en la Clase 29); esta pantalla es el adelanto prometido —
/// usa las posiciones de ojos, nariz y boca para colocar lentes y un
/// bigote sobre cada rostro detectado, el mismo principio que usan los
/// filtros de cámara de cualquier red social.
class FiltrosFacialesScreen extends StatefulWidget {
  const FiltrosFacialesScreen({super.key});

  @override
  State<FiltrosFacialesScreen> createState() => _FiltrosFacialesScreenState();
}

class _FiltrosFacialesScreenState extends State<FiltrosFacialesScreen> {
  ui.Image? _decodedImage;
  ui.Image? _glassesImage;
  ui.Image? _mustacheImage;
  List<Face> _faces = [];
  bool _isProcessing = false;
  bool _showGlasses = true;
  bool _showMustache = true;
  String _status = 'Selecciona una foto con al menos un rostro, de frente y bien iluminado.';

  // Un único FaceDetector, reutilizado para cada foto y cerrado en
  // dispose() — la misma buena práctica de la pantalla "ML Kit básico".
  late final FaceDetector _faceDetector;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
      ),
    );
    _loadOverlayAssets();
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

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _pickAndDetect(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 90,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    if (!mounted) return;
    setState(() {
      _decodedImage = frame.image;
      _faces = [];
      _status = 'Detectando rostros...';
    });

    await _detectFaces(file);
  }

  Future<void> _detectFaces(File file) async {
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      // Mismo patrón de siempre: archivo -> InputImage -> procesador ->
      // resultado. Aquí el resultado trae, además del cuadro delimitador,
      // los landmarks de cada rostro.
      final inputImage = InputImage.fromFile(file);
      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted) return;
      setState(() {
        _faces = faces;
        _isProcessing = false;
        if (faces.isEmpty) {
          _status = 'No se detectó ningún rostro. Prueba con una foto de '
              'frente, con buena luz y sin obstrucciones.';
        } else {
          final sinLandmarks = faces
              .where((f) => f.landmarks[FaceLandmarkType.leftEye] == null ||
                  f.landmarks[FaceLandmarkType.rightEye] == null)
              .length;
          _status = '${faces.length} rostro(s) detectado(s).'
              '${sinLandmarks > 0 ? ' $sinLandmarks sin landmarks completos '
                  '(rostro de perfil o parcialmente oculto): el filtro no '
                  'se dibuja ahí.' : ' Activa o desactiva los filtros abajo.'}';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _status = 'Ocurrió un error al detectar rostros: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Filtros faciales')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'FaceDetector(enableLandmarks: true) no solo cuenta rostros: '
            'devuelve puntos clave (ojos, nariz, boca) que se pueden usar '
            'para colocar algo sobre la cara — el mismo principio detrás de '
            'cualquier filtro de cámara.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          if (_decodedImage != null)
            AspectRatio(
              aspectRatio: _decodedImage!.width / _decodedImage!.height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  painter: FiltrosFacialesPainter(
                    image: _decodedImage!,
                    faces: _faces,
                    glasses: _showGlasses ? _glassesImage : null,
                    mustache: _showMustache ? _mustacheImage : null,
                  ),
                ),
              ),
            )
          else
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.face_outlined, size: 48, color: Colors.grey),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickAndDetect(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galería'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickAndDetect(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Cámara'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Lentes'),
            value: _showGlasses,
            onChanged: _decodedImage == null
                ? null
                : (v) => setState(() => _showGlasses = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Bigote'),
            value: _showMustache,
            onChanged: _decodedImage == null
                ? null
                : (v) => setState(() => _showMustache = v),
          ),
          const SizedBox(height: 8),
          Text(_status, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Dibuja la foto decodificada y, sobre cada rostro detectado, los
/// overlays (lentes/bigote) posicionados, rotados y escalados a partir
/// de los landmarks de ese rostro.
///
class FiltrosFacialesPainter extends CustomPainter {
  final ui.Image image;
  final List<Face> faces;
  final ui.Image? glasses;
  final ui.Image? mustache;

  FiltrosFacialesPainter({
    required this.image,
    required this.faces,
    required this.glasses,
    required this.mustache,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / image.width, size.height / image.height);

    canvas.drawImage(image, Offset.zero, Paint());

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
  bool shouldRepaint(covariant FiltrosFacialesPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.faces != faces ||
        oldDelegate.glasses != glasses ||
        oldDelegate.mustache != mustache;
  }
}

/// Carga un PNG de los assets como ui.Image (lo que necesita
/// Canvas.drawImage). Lo usan las dos pantallas de filtros.
Future<ui.Image> cargarImagenDeAsset(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  return frame.image;
}

/// Dibuja lentes y bigote sobre UN rostro, usando sus landmarks. El canvas
/// debe estar ya en coordenadas de la imagen que procesó ML Kit. Es la
/// misma geometría para la foto y para el video en vivo: solo cambia de
/// dónde viene el Face.
void pintarFiltrosEnRostro({
  required Canvas canvas,
  required Face face,
  required ui.Image? glasses,
  required ui.Image? mustache,
}) {
  final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
  final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
  final noseBase = face.landmarks[FaceLandmarkType.noseBase]?.position;
  final leftMouth = face.landmarks[FaceLandmarkType.leftMouth]?.position;
  final rightMouth = face.landmarks[FaceLandmarkType.rightMouth]?.position;
  final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth]?.position;

  if (glasses != null && leftEye != null && rightEye != null) {
    _drawBetweenAnchors(
      canvas: canvas,
      overlay: glasses,
      anchorA: Offset(leftEye.x.toDouble(), leftEye.y.toDouble()),
      anchorB: Offset(rightEye.x.toDouble(), rightEye.y.toDouble()),
      widthFactor: 2.3,
    );
  }

  if (mustache != null && leftMouth != null && rightMouth != null) {
    final centerX = (leftMouth.x + rightMouth.x) / 2.0;
    final mouthTopY = bottomMouth != null
        ? bottomMouth.y.toDouble()
        : (leftMouth.y + rightMouth.y) / 2.0;
    // El bigote va entre la base de la nariz y la boca; si no hay
    // noseBase (p. ej. rostro muy rotado), se estima subiendo un poco
    // desde la boca.
    final centerY = noseBase != null
        ? (noseBase.y.toDouble() + mouthTopY) / 2.0
        : mouthTopY - 14;
    final angle = math.atan2(
      (rightMouth.y - leftMouth.y).toDouble(),
      (rightMouth.x - leftMouth.x).toDouble(),
    );
    final mouthWidth = (rightMouth.x - leftMouth.x).abs().toDouble();
    _drawAt(
      canvas: canvas,
      overlay: mustache,
      center: Offset(centerX, centerY),
      angle: angle,
      targetWidth: mouthWidth * 1.7,
    );
  }
}

void _drawBetweenAnchors({
  required Canvas canvas,
  required ui.Image overlay,
  required Offset anchorA,
  required Offset anchorB,
  required double widthFactor,
}) {
  final center = Offset(
    (anchorA.dx + anchorB.dx) / 2,
    (anchorA.dy + anchorB.dy) / 2,
  );
  final dx = anchorB.dx - anchorA.dx;
  final dy = anchorB.dy - anchorA.dy;
  final distance = math.sqrt(dx * dx + dy * dy);
  final angle = math.atan2(dy, dx);
  _drawAt(
    canvas: canvas,
    overlay: overlay,
    center: center,
    angle: angle,
    targetWidth: distance * widthFactor,
  );
}

void _drawAt({
  required Canvas canvas,
  required ui.Image overlay,
  required Offset center,
  required double angle,
  required double targetWidth,
}) {
  final scaleFactor = targetWidth / overlay.width;
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);
  canvas.scale(scaleFactor);
  canvas.drawImage(
    overlay,
    Offset(-overlay.width / 2, -overlay.height / 2),
    Paint(),
  );
  canvas.restore();
}
