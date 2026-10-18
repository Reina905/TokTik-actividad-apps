import 'dart:io';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:toktok/presentation/widgets/filters/face_filter_utils.dart';

/// Servicio que quema el overlay de un filtro de rostro directamente
/// en el archivo de video usando FFmpeg.
///
/// Flujo:
///  1. [renderFilterOverlay] pinta los overlays del filtro sobre un canvas
///     transparente (mismas dimensiones que el video) y lo exporta como PNG.
///  2. [burnFilterIntoVideo] llama a FFmpeg para componer ese PNG sobre el video.
///  3. [applyFilterToVideo] orquesta ambos pasos y devuelve el archivo resultante.
class VideoFilterService {
  /// Renderiza el overlay del filtro para los [faces] detectados en un canvas
  /// transparente de [videoWidth] × [videoHeight] y lo guarda como PNG temporal.
  ///
  /// [frameSize] es el tamaño de la imagen que usó ML Kit para detectar los
  /// rostros — se necesita para escalar correctamente las coordenadas.
  ///
  /// Devuelve null si el filtro es [FaceFilterType.none] o no hay rostros.
  static Future<File?> renderFilterOverlay({
    required List<Face> faces,
    required FaceFilterAssets filterAssets,
    required FaceFilterType filterType,
    required int videoWidth,
    required int videoHeight,
    required Size frameSize,
    required bool mirror,
  }) async {
    if (filterType == FaceFilterType.none || faces.isEmpty) return null;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Escalar desde las coordenadas de ML Kit al tamaño real del video.
    final scaleX = videoWidth / frameSize.width;
    final scaleY = videoHeight / frameSize.height;

    canvas.save();

    // La cámara frontal graba con espejo → ML Kit entrega coords sin espejo.
    // FFmpeg también graba sin espejo → solo necesitamos la escala básica.
    if (mirror) {
      // Reflejar horizontalmente para que el overlay coincida con el video
      // grabado (que *no* está especulado a diferencia del preview).
      canvas.translate(videoWidth.toDouble(), 0);
      canvas.scale(-1, 1);
    }

    canvas.scale(scaleX, scaleY);

    for (final face in faces) {
      paintFilterOnFace(
        canvas: canvas,
        face: face,
        assets: filterAssets,
        filterType: filterType,
      );
    }

    canvas.restore();

    final picture = recorder.endRecording();
    final rendered = await picture.toImage(videoWidth, videoHeight);
    final byteData = await rendered.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final overlayFile = File(
      '${Directory.systemTemp.path}'
      '/filter_overlay_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await overlayFile.writeAsBytes(byteData.buffer.asUint8List());
    return overlayFile;
  }

  /// Usa FFmpeg para componer [overlayPng] sobre [inputVideo] y guarda el
  /// resultado en [outputVideo].
  ///
  /// El overlay PNG tiene el mismo tamaño que el video, por lo que no
  /// necesita escala adicional — solo se superpone en la posición (0,0).
  static Future<bool> burnFilterIntoVideo({
    required File inputVideo,
    required File overlayPng,
    required File outputVideo,
    void Function(double progress)? onProgress,
  }) async {
    // Obtener duración del video para calcular progreso (opcional).
    // Comando FFmpeg:
    //   -i video.mp4  (video original)
    //   -i overlay.png  (imagen del filtro, mismo tamaño que el video)
    //   -filter_complex "[0:v][1:v]overlay=0:0:format=auto[out]"
    //   -map "[out]" -map 0:a?  (preservar audio si existe)
    //   -c:v libx264 -preset ultrafast -crf 23
    //   -c:a copy  (audio sin recodificar)
    //   -movflags +faststart  (optimizar para streaming)
    //   output.mp4

    final inputPath = inputVideo.path;
    final overlayPath = overlayPng.path;
    final outputPath = outputVideo.path;

    final command =
        '-i "$inputPath" '
        '-i "$overlayPath" '
        '-filter_complex "[0:v][1:v]overlay=0:0:format=auto[out]" '
        '-map "[out]" -map 0:a? '
        '-c:v libx264 -preset ultrafast -crf 23 '
        '-c:a copy '
        '-movflags +faststart '
        '"$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    return ReturnCode.isSuccess(returnCode);
  }

  /// Aplica el filtro [filterType] al video [inputVideo] y devuelve el
  /// archivo resultante con el filtro quemado.
  ///
  /// Si el filtro es [FaceFilterType.none] o no hay rostros detectados,
  /// devuelve [inputVideo] sin modificar.
  ///
  /// Los parámetros [videoWidth], [videoHeight] y [frameSize] se usan
  /// para escalar correctamente las coordenadas de ML Kit al tamaño
  /// real del video.
  static Future<File> applyFilterToVideo({
    required File inputVideo,
    required List<Face> faces,
    required FaceFilterAssets filterAssets,
    required FaceFilterType filterType,
    required int videoWidth,
    required int videoHeight,
    required Size frameSize,
    required bool mirror,
    void Function(double progress)? onProgress,
  }) async {
    if (filterType == FaceFilterType.none || faces.isEmpty) {
      return inputVideo;
    }

    // 1. Renderizar el overlay como PNG transparente
    final overlayFile = await renderFilterOverlay(
      faces: faces,
      filterAssets: filterAssets,
      filterType: filterType,
      videoWidth: videoWidth,
      videoHeight: videoHeight,
      frameSize: frameSize,
      mirror: mirror,
    );

    if (overlayFile == null) return inputVideo;

    // 2. Definir la ruta del video de salida
    final outputFile = File(
      '${Directory.systemTemp.path}'
      '/filtered_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );

    // 3. Componer el overlay sobre el video con FFmpeg
    final success = await burnFilterIntoVideo(
      inputVideo: inputVideo,
      overlayPng: overlayFile,
      outputVideo: outputFile,
      onProgress: onProgress,
    );

    // 4. Limpiar el PNG temporal
    try {
      await overlayFile.delete();
    } catch (_) {}

    if (success && await outputFile.exists()) {
      return outputFile;
    }

    // Si FFmpeg falló, devolver el video original sin modificar
    return inputVideo;
  }
}
