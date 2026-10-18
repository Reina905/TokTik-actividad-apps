import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'face_filter_utils.dart';

/// Dibuja los overlays del filtro encima del CameraPreview en tiempo real.
/// No dibuja el video — de eso se encarga CameraPreview.
class LiveFilterPainter extends CustomPainter {
  final List<Face> faces;
  final Size frameSize;
  final bool mirror; // true para cámara frontal (selfie)
  final FaceFilterAssets filterAssets;

  const LiveFilterPainter({
    required this.faces,
    required this.frameSize,
    required this.mirror,
    required this.filterAssets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // La cámara frontal muestra el preview como espejo, pero ML Kit
    // entrega coordenadas sin espejar → reflejamos el canvas en X.
    if (mirror) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    canvas.scale(size.width / frameSize.width, size.height / frameSize.height);

    for (final face in faces) {
      paintFilterOnFace(
        canvas: canvas,
        face: face,
        assets: filterAssets,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LiveFilterPainter old) {
    return old.faces != faces ||
        old.frameSize != frameSize ||
        old.mirror != mirror ||
        old.filterAssets != filterAssets;
  }
}
