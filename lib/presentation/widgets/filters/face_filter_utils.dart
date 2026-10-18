import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

// ─── Modelo de filtro ─────────────────────────────────────────────────────────

enum FaceFilterType { none, reno, minion }

class FaceFilterAssets {
  /// Imagen superior: diadema de reno (sobre la cabeza) o gafas de minion (sobre los ojos)
  final ui.Image? top;

  /// Imagen inferior: nariz de reno o boca de minion
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
  required FaceFilterType filterType,
}) {
  final box = face.boundingBox;
  final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
  final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
  final noseBase = face.landmarks[FaceLandmarkType.noseBase]?.position;
  var leftMouth = face.landmarks[FaceLandmarkType.leftMouth]?.position;
  var rightMouth = face.landmarks[FaceLandmarkType.rightMouth]?.position;
  final leftEar = face.landmarks[FaceLandmarkType.leftEar]?.position;
  final rightEar = face.landmarks[FaceLandmarkType.rightEar]?.position;

  // Si ML Kit no da landmarks, estimamos ojos y boca con el bounding box
  // para que el filtro no desaparezca en video.
  final eyeLeft = leftEye != null
      ? Offset(leftEye.x.toDouble(), leftEye.y.toDouble())
      : Offset(box.left + box.width * 0.3, box.top + box.height * 0.38);
  final eyeRight = rightEye != null
      ? Offset(rightEye.x.toDouble(), rightEye.y.toDouble())
      : Offset(box.left + box.width * 0.7, box.top + box.height * 0.38);
  leftMouth ??= math.Point(
    (box.left + box.width * 0.35).round(),
    (box.top + box.height * 0.75).round(),
  );
  rightMouth ??= math.Point(
    (box.left + box.width * 0.65).round(),
    (box.top + box.height * 0.75).round(),
  );
  final eyeDistance = (eyeRight - eyeLeft).distance;
  final eyeCenter = (eyeLeft + eyeRight) / 2;

  // Ángulo de inclinación de la cabeza (rotación del canvas)
  final headAngle = math.atan2(
    eyeRight.dy - eyeLeft.dy,
    eyeRight.dx - eyeLeft.dx,
  );

  // Ancho de referencia: distancia entre orejas si están disponibles,
  // si no, se estima a partir de la distancia entre ojos.
  double headWidth = eyeDistance * 2.6;
  if (leftEar != null && rightEar != null) {
    headWidth =
        (Offset(rightEar.x.toDouble(), rightEar.y.toDouble()) -
                Offset(leftEar.x.toDouble(), leftEar.y.toDouble()))
            .distance *
        1.15;
  }

  switch (filterType) {
    case FaceFilterType.reno:
      _paintRenoFilter(
        canvas: canvas,
        assets: assets,
        eyeCenter: eyeCenter,
        eyeDistance: eyeDistance,
        headWidth: headWidth,
        headAngle: headAngle,
        noseBase: noseBase,
        leftMouth: leftMouth,
        rightMouth: rightMouth,
      );
      break;

    case FaceFilterType.minion:
      _paintMinionFilter(
        canvas: canvas,
        assets: assets,
        eyeLeft: eyeLeft,
        eyeRight: eyeRight,
        eyeCenter: eyeCenter,
        eyeDistance: eyeDistance,
        headWidth: headWidth,
        headAngle: headAngle,
        leftMouth: leftMouth,
        rightMouth: rightMouth,
      );
      break;

    case FaceFilterType.none:
      break;
  }
}

// ─── Filtro Reno ──────────────────────────────────────────────────────────────

void _paintRenoFilter({
  required Canvas canvas,
  required FaceFilterAssets assets,
  required Offset eyeCenter,
  required double eyeDistance,
  required double headWidth,
  required double headAngle,
  required math.Point<int>? noseBase,
  required math.Point<int>? leftMouth,
  required math.Point<int>? rightMouth,
}) {
  // ── Diadema (cuernos): debe quedar bien por encima de la frente ─────────
  // Se sube en la dirección perpendicular a la línea de los ojos.
  // Factor 1.5 → la diadema queda en la parte superior de la frente/cabeza.
  if (assets.top != null) {
    final perpAngle = headAngle - math.pi / 2;
    final offsetUp = eyeDistance * 1.5;
    final diademCenter = Offset(
      eyeCenter.dx + math.cos(perpAngle) * offsetUp,
      eyeCenter.dy + math.sin(perpAngle) * offsetUp,
    );

    _drawAt(
      canvas: canvas,
      overlay: assets.top!,
      center: diademCenter,
      angle: headAngle,
      // La diadema tiene el mismo ancho que la cabeza
      targetWidth: headWidth * 1.05,
    );
  }

  // ── Nariz roja: va justo sobre la boca / nariz ──────────────────────────
  if (assets.bottom != null && leftMouth != null && rightMouth != null) {
    final mLeft = Offset(leftMouth.x.toDouble(), leftMouth.y.toDouble());
    final mRight = Offset(rightMouth.x.toDouble(), rightMouth.y.toDouble());
    final mouthCenter = (mLeft + mRight) / 2;
    final mouthWidth = (mRight - mLeft).distance;
    final mouthAngle = math.atan2(
      mRight.dy - mLeft.dy,
      mRight.dx - mLeft.dx,
    );

    // La nariz roja queda entre la base de la nariz y la boca
    double noseY = mouthCenter.dy;
    if (noseBase != null) {
      noseY = noseBase.y.toDouble() +
          (mouthCenter.dy - noseBase.y.toDouble()) * 0.4;
    }

    _drawAt(
      canvas: canvas,
      overlay: assets.bottom!,
      center: Offset(mouthCenter.dx, noseY),
      angle: mouthAngle,
      targetWidth: mouthWidth * 1.4,
    );
  }
}

// ─── Filtro Minion ────────────────────────────────────────────────────────────

void _paintMinionFilter({
  required Canvas canvas,
  required FaceFilterAssets assets,
  required Offset eyeLeft,
  required Offset eyeRight,
  required Offset eyeCenter,
  required double eyeDistance,
  required double headWidth,
  required double headAngle,
  required math.Point<int>? leftMouth,
  required math.Point<int>? rightMouth,
}) {
  // ── Gafas/ojos de minion: centrados exactamente sobre los ojos ──────────
  // NO se sube — los ojos del minion deben coincidir con los ojos reales.
  // Se aplica un desplazamiento mínimo hacia arriba para que la montura
  // no tape los ojos (offset = eyeDistance * 0.05 es casi cero).
  if (assets.top != null) {
    final perpAngle = headAngle - math.pi / 2;
    // Desplazamiento muy pequeño para centrar las gafas sobre los ojos
    final offsetUp = eyeDistance * 0.05;
    final glassesCenter = Offset(
      eyeCenter.dx + math.cos(perpAngle) * offsetUp,
      eyeCenter.dy + math.sin(perpAngle) * offsetUp,
    );

    _drawAt(
      canvas: canvas,
      overlay: assets.top!,
      center: glassesCenter,
      angle: headAngle,
      // Ancho de las gafas = ancho de la cabeza para que cubran ambos ojos
      targetWidth: headWidth * 1.0,
    );
  }

  // ── Boca de minion: directamente en la boca de la persona ──────────────
  // No se promedia con noseBase; la boca del minion va sobre la boca real.
  if (assets.bottom != null && leftMouth != null && rightMouth != null) {
    final mLeft = Offset(leftMouth.x.toDouble(), leftMouth.y.toDouble());
    final mRight = Offset(rightMouth.x.toDouble(), rightMouth.y.toDouble());
    final mouthCenter = (mLeft + mRight) / 2;
    final mouthWidth = (mRight - mLeft).distance;
    final mouthAngle = math.atan2(
      mRight.dy - mLeft.dy,
      mRight.dx - mLeft.dx,
    );

    // Ligeramente abajo desde el centro de la boca para incluir la
    // parte inferior del labio
    final perpAngle = mouthAngle - math.pi / 2;
    final offsetDown = mouthWidth * 0.1;
    final minionMouthCenter = Offset(
      mouthCenter.dx - math.cos(perpAngle) * offsetDown,
      mouthCenter.dy - math.sin(perpAngle) * offsetDown,
    );

    _drawAt(
      canvas: canvas,
      overlay: assets.bottom!,
      center: minionMouthCenter,
      angle: mouthAngle,
      targetWidth: mouthWidth * 2.2,
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
  if (targetWidth <= 0) return;
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
