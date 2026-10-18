import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'face_filter_utils.dart';

/// Dibuja la foto estática más los overlays del filtro encima.
/// Se usa en la pantalla de upload al seleccionar una imagen de la galería.
class StaticFilterPainter extends CustomPainter {
  final ui.Image image;
  final List<Face> faces;
  final FaceFilterAssets filterAssets;
  final FaceFilterType filterType;

  const StaticFilterPainter({
    required this.image,
    required this.faces,
    required this.filterAssets,
    required this.filterType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Escala el canvas para que las coordenadas de ML Kit (píxeles de la
    // imagen original) caigan exactamente sobre el widget renderizado.
    canvas.scale(size.width / image.width, size.height / image.height);

    canvas.drawImage(image, Offset.zero, Paint());

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
  bool shouldRepaint(covariant StaticFilterPainter old) {
    return old.image != image ||
        old.faces != faces ||
        old.filterAssets != filterAssets ||
        old.filterType != filterType;
  }
}
