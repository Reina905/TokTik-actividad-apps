import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';
import 'package:toktok/presentation/providers/discover_provider.dart';
import 'package:toktok/presentation/providers/upload_video_provider.dart';
import 'package:toktok/presentation/widgets/filters/face_filter_utils.dart';
import 'package:toktok/presentation/widgets/filters/filter_selector.dart';
import 'package:toktok/presentation/widgets/filters/static_filter_painter.dart';

class UploadScreen extends StatefulWidget {
  final File file;
  final bool isVideo;

  const UploadScreen({
    super.key,
    required this.file,
    required this.isVideo,
  });

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _captionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ── Filtros (solo para fotos) ─────────────────────────────────────────────
  ui.Image? _decodedImage;
  List<Face> _faces = [];
  FaceFilterType _selectedFilter = FaceFilterType.none;
  FaceFilterAssets _filterAssets = FaceFilterAssets.empty();
  bool _isDetecting = false;

  late final FaceDetector _faceDetector;

  @override
  void initState() {
    super.initState();
    if (!widget.isVideo) {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableLandmarks: true,
        ),
      );
      _loadImageAndDetect();
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    if (!widget.isVideo) _faceDetector.close();
    super.dispose();
  }

  // ── Carga de imagen y detección ───────────────────────────────────────────

  Future<void> _loadImageAndDetect() async {
    setState(() => _isDetecting = true);

    final bytes = await widget.file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    if (!mounted) return;
    setState(() => _decodedImage = frame.image);

    final inputImage = InputImage.fromFile(widget.file);
    final faces = await _faceDetector.processImage(inputImage);

    if (!mounted) return;
    setState(() {
      _faces = faces;
      _isDetecting = false;
    });
  }

  Future<void> _onFilterSelected(FaceFilterType type) async {
    final assets = await loadFilterAssets(type);
    if (!mounted) return;
    setState(() {
      _selectedFilter = type;
      _filterAssets = assets;
    });
  }

  // ── Renderizado de foto con filtro ────────────────────────────────────────

  /// Renderiza la imagen con el filtro aplicado a un archivo temporal.
  /// Devuelve null si no hay filtro o si falla (se sube el original).
  Future<File?> _renderFilteredImage() async {
    if (_selectedFilter == FaceFilterType.none || _decodedImage == null) {
      return null;
    }
    try {
      final image = _decodedImage!;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // Pintar imagen + overlays del filtro a resolución original
      final painter = StaticFilterPainter(
        image: image,
        faces: _faces,
        filterAssets: _filterAssets,
      );
      painter.paint(
        canvas,
        Size(image.width.toDouble(), image.height.toDouble()),
      );

      final picture = recorder.endRecording();
      final rendered = await picture.toImage(image.width, image.height);
      final byteData = await rendered.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final tempFile = File(
        '${Directory.systemTemp.path}/'
        'filtered_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());
      return tempFile;
    } catch (_) {
      return null;
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Guardar referencias antes de los async gaps
    final uploadProvider = context.read<UploadVideoProvider>();
    final userId = context.read<AuthProvider>().userId;
    final discoverProvider = context.read<DiscoverProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Si es foto con filtro, renderizar la imagen con el filtro aplicado
    File fileToUpload = widget.file;
    if (!widget.isVideo && _selectedFilter != FaceFilterType.none) {
      final rendered = await _renderFilteredImage();
      if (rendered != null) {
        fileToUpload = rendered;
      }
    }

    final success = await uploadProvider.uploadFile(
      file: fileToUpload,
      caption: _captionController.text.trim(),
      isVideo: widget.isVideo,
      userId: userId,
    );

    if (!mounted) return;

    if (success) {
      // Refrescar el feed para que aparezca el video/foto nuevo
      discoverProvider.reload();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.isVideo
                ? '¡Video publicado exitosamente!'
                : '¡Foto publicada exitosamente!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop();
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UploadVideoProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.isVideo ? 'Nuevo video' : 'Nueva foto',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: provider.isUploading
          ? _UploadingView(progress: provider.progress, isVideo: widget.isVideo)
          : _FormView(
              captionController: _captionController,
              formKey: _formKey,
              file: widget.file,
              isVideo: widget.isVideo,
              decodedImage: _decodedImage,
              faces: _faces,
              filterAssets: _filterAssets,
              selectedFilter: _selectedFilter,
              isDetecting: _isDetecting,
              onFilterSelected: widget.isVideo ? null : _onFilterSelected,
              errorMessage: provider.errorMessage,
              onSubmit: _submit,
            ),
    );
  }
}

// ─── Vista del formulario ─────────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  final TextEditingController captionController;
  final GlobalKey<FormState> formKey;
  final File file;
  final bool isVideo;
  final ui.Image? decodedImage;
  final List<Face> faces;
  final FaceFilterAssets filterAssets;
  final FaceFilterType selectedFilter;
  final bool isDetecting;
  final ValueChanged<FaceFilterType>? onFilterSelected;
  final String? errorMessage;
  final VoidCallback onSubmit;

  const _FormView({
    required this.captionController,
    required this.formKey,
    required this.file,
    required this.isVideo,
    required this.decodedImage,
    required this.faces,
    required this.filterAssets,
    required this.selectedFilter,
    required this.isDetecting,
    required this.onFilterSelected,
    required this.errorMessage,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Preview con filtro ────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: double.infinity,
                height: 220,
                child: isVideo
                    ? _VideoPreview(file: file)
                    : _PhotoPreview(
                        file: file,
                        decodedImage: decodedImage,
                        faces: faces,
                        filterAssets: filterAssets,
                        isDetecting: isDetecting,
                      ),
              ),
            ),

            // ── Selector de filtro (solo fotos) ───────────────────────────
            if (!isVideo && onFilterSelected != null) ...[
              const SizedBox(height: 12),
              FilterSelector(
                selected: selectedFilter,
                onSelect: onFilterSelected!,
              ),
            ],

            const SizedBox(height: 20),

            // ── Campo de descripción ──────────────────────────────────────
            Text(
              isVideo ? 'Descripción del video' : 'Descripción de la foto',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: captionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              maxLength: 150,
              decoration: InputDecoration(
                hintText: isVideo
                    ? 'Describe tu video...'
                    : 'Describe tu foto...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterStyle: const TextStyle(color: Colors.white38),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Agrega una descripción';
                }
                return null;
              },
            ),

            // ── Error ─────────────────────────────────────────────────────
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ── Botón publicar ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEE1D52),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Publicar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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

// ─── Preview de video ─────────────────────────────────────────────────────────

class _VideoPreview extends StatelessWidget {
  final File file;
  const _VideoPreview({required this.file});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white10,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam, color: Colors.white54, size: 48),
          const SizedBox(height: 8),
          Text(
            file.path.split('/').last,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Preview de foto con filtro ───────────────────────────────────────────────

class _PhotoPreview extends StatelessWidget {
  final File file;
  final ui.Image? decodedImage;
  final List<Face> faces;
  final FaceFilterAssets filterAssets;
  final bool isDetecting;

  const _PhotoPreview({
    required this.file,
    required this.decodedImage,
    required this.faces,
    required this.filterAssets,
    required this.isDetecting,
  });

  @override
  Widget build(BuildContext context) {
    if (isDetecting) {
      return Container(
        color: Colors.white10,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFEE1D52)),
              SizedBox(height: 12),
              Text(
                'Detectando rostros...',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (decodedImage == null) {
      return Image.file(file, fit: BoxFit.cover);
    }

    return AspectRatio(
      aspectRatio: decodedImage!.width / decodedImage!.height,
      child: CustomPaint(
        painter: StaticFilterPainter(
          image: decodedImage!,
          faces: faces,
          filterAssets: filterAssets,
        ),
      ),
    );
  }
}

// ─── Vista de progreso de subida ──────────────────────────────────────────────

class _UploadingView extends StatelessWidget {
  final double progress;
  final bool isVideo;
  const _UploadingView({required this.progress, required this.isVideo});

  String get _statusText {
    if (progress < 0.5) return 'Subiendo a Cloudinary...';
    if (progress < 0.9) return 'Guardando en Firestore...';
    return '¡Casi listo!';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isVideo ? Icons.cloud_upload : Icons.photo_camera,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              _statusText,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white12,
                valueColor:
                    const AlwaysStoppedAnimation(Color(0xFFEE1D52)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
