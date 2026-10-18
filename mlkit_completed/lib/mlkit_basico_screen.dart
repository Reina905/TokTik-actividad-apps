import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Pantalla "ML Kit básico": los tres reconocedores del guion de la
/// Clase 24, siguiendo exactamente el patrón del libro de referencia
/// (Flutter Cookbook, Cap. 14): InputImage -> procesador -> resultado,
/// procesadores declarados como campos reutilizables, cerrados en
/// dispose(), y bandera isProcessing para evitar solapar reconocimientos.
class MLKitBasicoScreen extends StatefulWidget {
  const MLKitBasicoScreen({super.key});

  @override
  State<MLKitBasicoScreen> createState() => _MLKitBasicoScreenState();
}

class _MLKitBasicoScreenState extends State<MLKitBasicoScreen> {
  File? _image;
  String _result = 'Selecciona o captura una imagen para comenzar.';
  bool _isProcessing = false;

  // Los tres procesadores se crean UNA sola vez (initState) y se cierran
  // en dispose(): crearlos dentro de cada botón sería el error de
  // rendimiento que señala la pregunta 16 del banco de repaso.
  late final TextRecognizer _textRecognizer;
  late final ImageLabeler _imageLabeler;
  late final FaceDetector _faceDetector;

  @override
  void initState() {
    super.initState();
    _textRecognizer = TextRecognizer();
    _imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.7),
    );
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
        enableClassification: true,
      ),
    );
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _imageLabeler.close();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _getImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _image = File(picked.path);
      _result = 'Imagen lista. Elige un reconocedor.';
    });
  }

  Future<void> _runTextRecognition() async {
    if (_image == null || _isProcessing) return;
    _isProcessing = true;
    try {
      final inputImage = InputImage.fromFile(_image!);
      final recognized = await _textRecognizer.processImage(inputImage);
      if (!mounted) return;
      setState(() {
        _result = recognized.text.isEmpty
            ? 'TextRecognizer no encontró texto reconocible en la imagen.'
            : 'Texto reconocido:\n\n${recognized.text}';
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _result = 'Ocurrió un error al reconocer texto: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _runImageLabeling() async {
    if (_image == null || _isProcessing) return;
    _isProcessing = true;
    try {
      final inputImage = InputImage.fromFile(_image!);
      final labels = await _imageLabeler.processImage(inputImage);
      if (!mounted) return;
      if (labels.isEmpty) {
        setState(() {
          _result = 'ImageLabeler no encontró etiquetas con confianza >= 70%.';
          _isProcessing = false;
        });
        return;
      }
      final buffer = StringBuffer('Etiquetas detectadas:\n\n');
      for (final label in labels) {
        buffer.writeln(
          '${label.index}: ${label.label} — ${(label.confidence * 100).toStringAsFixed(1)}%',
        );
      }
      setState(() {
        _result = buffer.toString();
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _result = 'Ocurrió un error al etiquetar la imagen: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _runFaceDetection() async {
    if (_image == null || _isProcessing) return;
    _isProcessing = true;
    try {
      final inputImage = InputImage.fromFile(_image!);
      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted) return;
      final buffer = StringBuffer(
        'Hay ${faces.length} rostro(s) en la imagen.\n\n',
      );
      for (var i = 0; i < faces.length; i++) {
        final face = faces[i];
        buffer.writeln('Rostro ${i + 1}');
        buffer.writeln('Cuadro delimitador: ${face.boundingBox}');
        final smiling = face.smilingProbability;
        final leftEyeOpen = face.leftEyeOpenProbability;
        final rightEyeOpen = face.rightEyeOpenProbability;
        if (smiling != null) {
          buffer.writeln('Sonriendo: ${(smiling * 100).toStringAsFixed(1)}%');
        }
        if (leftEyeOpen != null) {
          buffer.writeln(
            'Ojo izquierdo abierto: ${(leftEyeOpen * 100).toStringAsFixed(1)}%',
          );
        }
        if (rightEyeOpen != null) {
          buffer.writeln(
            'Ojo derecho abierto: ${(rightEyeOpen * 100).toStringAsFixed(1)}%',
          );
        }
        buffer.writeln();
      }
      setState(() {
        _result = buffer.toString();
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _result = 'Ocurrió un error al detectar rostros: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ML Kit básico')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 200, fit: BoxFit.cover),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.image_outlined, size: 48, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _getImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galería'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _getImage(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Cámara'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _image == null || _isProcessing
                  ? null
                  : _runTextRecognition,
              child: const Text('Text Recognition'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _image == null || _isProcessing
                  ? null
                  : _runImageLabeling,
              child: const Text('Image Labeling'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _image == null || _isProcessing
                  ? null
                  : _runFaceDetection,
              child: const Text('Face Detection'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(_result),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
