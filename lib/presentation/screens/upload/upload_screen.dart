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
import 'package:video_player/video_player.dart';

class UploadScreen extends StatefulWidget {
  final File file;
  final bool isVideo;
  /// Filtro ya seleccionado (cuando viene desde la cámara con filtro activo)
  final FaceFilterType initialFilter;
  final FaceFilterAssets initialFilterAssets;
  final List<Face> initialFaces;

  const UploadScreen({
    super.key,
    required this.file,
    required this.isVideo,
    this.initialFilter = FaceFilterType.none,
    this.initialFilterAssets = const FaceFilterAssets(),
    this.initialFaces = const [],
  });

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _captionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ── Filtros ───────────────────────────────────────────────────────────────
  ui.Image? _decodedImage;
  List<Face> _faces = [];
  FaceFilterType _selectedFilter = FaceFilterType.none;
  FaceFilterAssets _filterAssets = FaceFilterAssets.empty();
  bool _isDetecting = false;

  // ── Video preview ─────────────────────────────────────────────────────────
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;

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

    // Aplicar filtro inicial si viene desde la cámara con filtro activo
    _selectedFilter = widget.initialFilter;
    _filterAssets = widget.initialFilterAssets;
    _faces = List<Face>.from(widget.initialFaces);

    if (widget.isVideo) {
      _initVideoPlayer();
    } else {
      _loadImageAndDetect();
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _faceDetector.close();
    _videoController?.dispose();
    super.dispose();
  }

  // ── Video player ──────────────────────────────────────────────────────────

  Future<void> _initVideoPlayer() async {
    final controller = VideoPlayerController.file(widget.file);
    _videoController = controller;
    await controller.initialize();
    if (!mounted) return;
    controller.setLooping(true);
    controller.play();
    setState(() => _videoInitialized = true);

    // Solo detectar rostros en el archivo si no vienen pre-detectados
    // desde la cámara en vivo.
    if (_faces.isEmpty) {
      await _detectFacesInVideoFrame();
    }
  }

  Future<void> _detectFacesInVideoFrame() async {
    setState(() => _isDetecting = true);
    try {
      final inputImage = InputImage.fromFile(widget.file);
      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted) return;
      setState(() {
        _faces = faces;
        _isDetecting = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isDetecting = false);
    }
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

  Future<File?> _renderFilteredImage() async {
    if (_selectedFilter == FaceFilterType.none || _decodedImage == null) {
      return null;
    }
    try {
      final image = _decodedImage!;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      final painter = StaticFilterPainter(
        image: image,
        faces: _faces,
        filterAssets: _filterAssets,
        filterType: _selectedFilter,
      );
      painter.paint(
        canvas,
        Size(image.width.toDouble(), image.height.toDouble()),
      );

      final picture = recorder.endRecording();
      final rendered = await picture.toImage(image.width, image.height);
      final byteData =
          await rendered.toByteData(format: ui.ImageByteFormat.png);
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

    final uploadProvider = context.read<UploadVideoProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    final userName = authProvider.userName;
    final discoverProvider = context.read<DiscoverProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // 1. Renderizar filtro en foto si corresponde
    File fileToUpload = widget.file;
    if (!widget.isVideo && _selectedFilter != FaceFilterType.none) {
      final rendered = await _renderFilteredImage();
      if (rendered != null) fileToUpload = rendered;
    }

    // 2. Subir el archivo principal a Cloudinary y guardar en Firestore.
    //    El thumbnailUrl se calcula a partir de la URL de Cloudinary
    //    ya subida usando _thumbnailUrlFromCloudinary().
    final success = await uploadProvider.uploadFile(
      file: fileToUpload,
      caption: _captionController.text.trim(),
      isVideo: widget.isVideo,
      userId: userId,
      userName: userName,
      // Se pasa null aquí; el repositorio lo recibirá del provider
      // una vez tengamos la cloudinaryUrl. Ver uploadFile() en el provider.
    );

    if (!mounted) return;

    if (success) {
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
              onFilterSelected: _onFilterSelected,
              videoController: _videoController,
              videoInitialized: _videoInitialized,
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
  final ValueChanged<FaceFilterType> onFilterSelected;
  final VideoPlayerController? videoController;
  final bool videoInitialized;
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
    required this.videoController,
    required this.videoInitialized,
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
                height: 320,
                child: isVideo
                    ? _VideoPreviewWithFilter(
                        file: file,
                        controller: videoController,
                        isInitialized: videoInitialized,
                        faces: faces,
                        filterAssets: filterAssets,
                        selectedFilter: selectedFilter,
                        isDetecting: isDetecting,
                      )
                    : _PhotoPreview(
                        file: file,
                        decodedImage: decodedImage,
                        faces: faces,
                        filterAssets: filterAssets,
                        selectedFilter: selectedFilter,
                        isDetecting: isDetecting,
                      ),
              ),
            ),

            // ── Selector de filtro ────────────────────────────────────────
            const SizedBox(height: 12),
            FilterSelector(
              selected: selectedFilter,
              onSelect: onFilterSelected,
            ),

            if (isVideo) ...[
              const SizedBox(height: 8),
              const Text(
                'El filtro se aplica visualmente. El video original se sube sin modificar.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
                textAlign: TextAlign.center,
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

// ─── Preview de video con overlay de filtro ───────────────────────────────────

class _VideoPreviewWithFilter extends StatelessWidget {
  final File file;
  final VideoPlayerController? controller;
  final bool isInitialized;
  final List<Face> faces;
  final FaceFilterAssets filterAssets;
  final FaceFilterType selectedFilter;
  final bool isDetecting;

  const _VideoPreviewWithFilter({
    required this.file,
    required this.controller,
    required this.isInitialized,
    required this.faces,
    required this.filterAssets,
    required this.selectedFilter,
    required this.isDetecting,
  });

  @override
  Widget build(BuildContext context) {
    if (!isInitialized || controller == null) {
      return Container(
        color: Colors.white10,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFEE1D52)),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller!.value.size.width,
            height: controller!.value.size.height,
            child: VideoPlayer(controller!),
          ),
        ),
        if (selectedFilter != FaceFilterType.none && faces.isNotEmpty)
          _VideoFilterOverlay(
            controller: controller!,
            faces: faces,
            filterAssets: filterAssets,
            selectedFilter: selectedFilter,
          ),
        if (isDetecting)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Detectando rostros...',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ),
          ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.videocam, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}

class _VideoFilterOverlay extends StatelessWidget {
  final VideoPlayerController controller;
  final List<Face> faces;
  final FaceFilterAssets filterAssets;
  final FaceFilterType selectedFilter;

  const _VideoFilterOverlay({
    required this.controller,
    required this.faces,
    required this.filterAssets,
    required this.selectedFilter,
  });

  @override
  Widget build(BuildContext context) {
    final videoSize = controller.value.size;
    if (videoSize.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final widgetSize = Size(constraints.maxWidth, constraints.maxHeight);
        final videoAspect = videoSize.width / videoSize.height;
        final widgetAspect = widgetSize.width / widgetSize.height;

        final Size renderSize;
        if (videoAspect > widgetAspect) {
          renderSize =
              Size(widgetSize.height * videoAspect, widgetSize.height);
        } else {
          renderSize =
              Size(widgetSize.width, widgetSize.width / videoAspect);
        }

        return CustomPaint(
          size: widgetSize,
          painter: _VideoOverlayPainter(
            faces: faces,
            frameSize: videoSize,
            renderSize: renderSize,
            widgetSize: widgetSize,
            filterAssets: filterAssets,
            filterType: selectedFilter,
          ),
        );
      },
    );
  }
}

class _VideoOverlayPainter extends CustomPainter {
  final List<Face> faces;
  final Size frameSize;
  final Size renderSize;
  final Size widgetSize;
  final FaceFilterAssets filterAssets;
  final FaceFilterType filterType;

  const _VideoOverlayPainter({
    required this.faces,
    required this.frameSize,
    required this.renderSize,
    required this.widgetSize,
    required this.filterAssets,
    required this.filterType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dx = (widgetSize.width - renderSize.width) / 2;
    final dy = (widgetSize.height - renderSize.height) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(
      renderSize.width / frameSize.width,
      renderSize.height / frameSize.height,
    );
    for (final face in faces) {
      paintFilterOnFace(
        canvas: canvas,
        face: face,
        assets: filterAssets,
        filterType: filterType,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _VideoOverlayPainter old) {
    return old.faces != faces ||
        old.filterType != filterType ||
        old.filterAssets != filterAssets;
  }
}

// ─── Preview de foto con filtro ───────────────────────────────────────────────

class _PhotoPreview extends StatelessWidget {
  final File file;
  final ui.Image? decodedImage;
  final List<Face> faces;
  final FaceFilterAssets filterAssets;
  final FaceFilterType selectedFilter;
  final bool isDetecting;

  const _PhotoPreview({
    required this.file,
    required this.decodedImage,
    required this.faces,
    required this.filterAssets,
    required this.selectedFilter,
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
          filterType: selectedFilter,
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
    if (progress < 0.3) return 'Generando miniatura...';
    if (progress < 0.6) return 'Subiendo a Cloudinary...';
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
