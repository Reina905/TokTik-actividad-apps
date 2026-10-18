import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

// ─── Modelo de filtro ─────────────────────────────────────────────────────────

enum FaceFilterType { none, reno, minion }

class FaceFilterAssets {
  /// Imagen que se coloca sobre los ojos / frente (diadema de reno o gafas minion)
  final ui.Image? top;

  /// Imagen que se coloca sobre la nariz / boca
  final ui.Image? bottom;

  const FaceFilterAssets({this.top, this.bottom});

  static FaceFilterAssets empty() => const FaceFilterAssets();
}

// ─── Carga de assets ──────────────────────────────────────────────────────────

Future<ui.Image> loadImageAsset(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  return frame.image;
}

Future<FaceFilterAssets> loadFilterAssets(FaceFilterType type) async {
  switch (type) {
    case FaceFilterType.reno:
      final top = await loadImageAsset('assets/filtros/reno_diadema.png');
      final bottom = await loadImageAsset('assets/filtros/reno_nariz.png');
      return FaceFilterAssets(top: top, bottom: bottom);
    case FaceFilterType.minion:
      final top = await loadImageAsset('assets/filtros/minion_ojos.png');
      final bottom = await loadImageAsset('assets/filtros/minion_boca.png');
      return FaceFilterAssets(top: top, bottom: bottom);
    case FaceFilterType.none:
      return FaceFilterAssets.empty();
  }
}

// ─── Lógica de dibujo (reutilizada por foto y cámara en vivo) ─────────────────

/// Dibuja los overlays del filtro sobre un rostro detectado.
/// El canvas debe estar ya escalado a las coordenadas de la imagen de ML Kit.
void paintFilterOnFace({
  required Canvas canvas,
  required Face face,
  required FaceFilterAssets assets,
}) {
  final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
  final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
  final noseBase = face.landmarks[FaceLandmarkType.noseBase]?.position;
  final leftMouth = face.landmarks[FaceLandmarkType.leftMouth]?.position;
  final rightMouth = face.landmarks[FaceLandmarkType.rightMouth]?.position;
  final leftEar = face.landmarks[FaceLandmarkType.leftEar]?.position;
  final rightEar = face.landmarks[FaceLandmarkType.rightEar]?.position;

  // ── Imagen superior (diadema reno / gafas minion) ────────────────────────
  if (assets.top != null && leftEye != null && rightEye != null) {
    final eyeLeft = Offset(leftEye.x.toDouble(), leftEye.y.toDouble());
    final eyeRight = Offset(rightEye.x.toDouble(), rightEye.y.toDouble());
    final eyeDistance = (eyeRight - eyeLeft).distance;
    final eyeCenter = (eyeLeft + eyeRight) / 2;
    final angle = math.atan2(
      eyeRight.dy - eyeLeft.dy,
      eyeRight.dx - eyeLeft.dx,
    );

    // La diadema/gafas se ancla en los ojos pero sube hacia la frente
    final offsetUp = eyeDistance * 0.6;
    final perpAngle = angle - math.pi / 2;
    final center = Offset(
      eyeCenter.dx + math.cos(perpAngle) * offsetUp,
      eyeCenter.dy + math.sin(perpAngle) * offsetUp,
    );

    // Ancho proporcional: si hay orejas usamos esa distancia, si no, los ojos × 2.4
    double targetWidth = eyeDistance * 2.4;
    if (leftEar != null && rightEar != null) {
      targetWidth =
          (Offset(rightEar.x.toDouble(), rightEar.y.toDouble()) -
                  Offset(leftEar.x.toDouble(), leftEar.y.toDouble()))
              .distance *
          1.1;
    }

    _drawAt(
      canvas: canvas,
      overlay: assets.top!,
      center: center,
      angle: angle,
      targetWidth: targetWidth,
    );
  }

  // ── Imagen inferior (nariz reno / boca minion) ───────────────────────────
  if (assets.bottom != null && leftMouth != null && rightMouth != null) {
    final mLeft = Offset(leftMouth.x.toDouble(), leftMouth.y.toDouble());
    final mRight = Offset(rightMouth.x.toDouble(), rightMouth.y.toDouble());
    final mouthWidth = (mRight - mLeft).distance;
    final mouthCenter = (mLeft + mRight) / 2;
    final angle = math.atan2(
      mRight.dy - mLeft.dy,
      mRight.dx - mLeft.dx,
    );

    // La nariz va entre la base de la nariz y la boca
    double centerY = mouthCenter.dy;
    if (noseBase != null) {
      centerY = (noseBase.y.toDouble() + mouthCenter.dy) / 2.0;
    }

    _drawAt(
      canvas: canvas,
      overlay: assets.bottom!,
      center: Offset(mouthCenter.dx, centerY),
      angle: angle,
      targetWidth: mouthWidth * 1.8,
    );
  }
}

// ─── Helpers internos ─────────────────────────────────────────────────────────

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
