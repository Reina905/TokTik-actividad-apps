import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:toktok/presentation/widgets/filters/face_filter_utils.dart';

/// Rostros detectados a lo largo del video, alineados con los PNG extraídos.
class VideoFaceTrack {
  final int fps;
  final Size frameSize;
  final List<List<Face>> facesPerFrame;
  final Directory framesDir;

  const VideoFaceTrack({
    required this.fps,
    required this.frameSize,
    required this.facesPerFrame,
    required this.framesDir,
  });

  bool get hasAnyFace => facesPerFrame.any((faces) => faces.isNotEmpty);

  List<Face> facesAt(Duration position) {
    if (facesPerFrame.isEmpty) return const [];
    final index = (position.inMilliseconds / 1000 * fps).floor();
    return facesPerFrame[index.clamp(0, facesPerFrame.length - 1)];
  }

  Future<void> dispose() async {
    await VideoFilterService.deleteDir(framesDir);
  }
}

/// Quema el filtro en el video pintándolo sobre cada fotograma extraído
/// y volviendo a ensamblar el archivo con FFmpeg.
class VideoFilterService {
  static const int _maxTrackingFps = 10;
  static const int _maxTrackedFrames = 150;
  static const int _holdMissingFrames = 5;

  static Future<File?> extractFirstFrame(File videoFile) async {
    final outputPath =
        '${Directory.systemTemp.path}'
        '/video_frame_${DateTime.now().millisecondsSinceEpoch}.png';

    final ok = await _run([
      '-y',
      '-ss',
      '0',
      '-i',
      videoFile.path,
      '-frames:v',
      '1',
      '-q:v',
      '2',
      outputPath,
    ]);
    if (!ok) return null;
    final frameFile = File(outputPath);
    return (await frameFile.exists()) ? frameFile : null;
  }

  /// Extrae fotogramas y detecta el rostro en cada uno.
  static Future<VideoFaceTrack?> analyzeVideo(
    File videoFile, {
    void Function(double progress)? onProgress,
  }) async {
    final duration = await _probeDuration(videoFile);
    final fps = _trackingFpsFor(duration);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final framesDir =
        Directory('${Directory.systemTemp.path}/vf_frames_$stamp');
    await framesDir.create(recursive: true);

    final detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
        enableTracking: true,
      ),
    );

    try {
      onProgress?.call(0.02);
      final extracted = await _extractFrames(videoFile, framesDir, fps);
      if (!extracted) {
        await deleteDir(framesDir);
        return null;
      }

      final frameFiles = _sortedPngs(framesDir);
      if (frameFiles.isEmpty) {
        await deleteDir(framesDir);
        return null;
      }

      Size? frameSize;
      final facesPerFrame = <List<Face>>[];
      List<Face> lastFaces = const [];
      var missing = 0;

      for (var i = 0; i < frameFiles.length; i++) {
        final frameFile = frameFiles[i];
        frameSize ??= await _imageSize(frameFile);

        List<Face> faces = const [];
        try {
          faces = await detector.processImage(InputImage.fromFile(frameFile));
        } catch (e) {
          debugPrint('ML Kit frame $i: $e');
        }

        if (faces.isNotEmpty) {
          lastFaces = faces;
          missing = 0;
          facesPerFrame.add(faces);
        } else if (lastFaces.isNotEmpty && missing < _holdMissingFrames) {
          missing++;
          facesPerFrame.add(lastFaces);
        } else {
          missing++;
          facesPerFrame.add(const []);
        }

        onProgress?.call(0.05 + 0.9 * ((i + 1) / frameFiles.length));
      }

      if (frameSize == null || frameSize.isEmpty) {
        await deleteDir(framesDir);
        return null;
      }

      return VideoFaceTrack(
        fps: fps,
        frameSize: frameSize,
        facesPerFrame: facesPerFrame,
        framesDir: framesDir,
      );
    } catch (e) {
      debugPrint('analyzeVideo: $e');
      await deleteDir(framesDir);
      return null;
    } finally {
      await detector.close();
    }
  }

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
    canvas.save();
    if (mirror) {
      canvas.translate(videoWidth.toDouble(), 0);
      canvas.scale(-1, 1);
    }
    canvas.scale(videoWidth / frameSize.width, videoHeight / frameSize.height);
    for (final face in faces) {
      paintFilterOnFace(
        canvas: canvas,
        face: face,
        assets: filterAssets,
        filterType: filterType,
      );
    }
    canvas.restore();

    final rendered =
        await recorder.endRecording().toImage(videoWidth, videoHeight);
    final byteData = await rendered.toByteData(format: ui.ImageByteFormat.png);
    rendered.dispose();
    if (byteData == null) return null;

    final overlayFile = File(
      '${Directory.systemTemp.path}'
      '/filter_overlay_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await overlayFile.writeAsBytes(byteData.buffer.asUint8List());
    return overlayFile;
  }

  static Future<bool> burnFilterIntoVideo({
    required File inputVideo,
    required File overlayPng,
    required File outputVideo,
    void Function(double progress)? onProgress,
  }) {
    return _run([
      '-y',
      '-i',
      inputVideo.path,
      '-i',
      overlayPng.path,
      '-filter_complex',
      '[0:v][1:v]overlay=0:0[out]',
      '-map',
      '[out]',
      '-map',
      '0:a?',
      '-c:v',
      'libx264',
      '-preset',
      'ultrafast',
      '-crf',
      '23',
      '-c:a',
      'copy',
      '-movflags',
      '+faststart',
      outputVideo.path,
    ]);
  }

  /// Pinta el filtro en cada fotograma y reconstruye el mp4.
  static Future<File> applyFilterToVideo({
    required File inputVideo,
    required FaceFilterAssets filterAssets,
    required FaceFilterType filterType,
    List<Face> faces = const [],
    int? videoWidth,
    int? videoHeight,
    Size? frameSize,
    bool mirror = false,
    VideoFaceTrack? track,
    void Function(double progress)? onProgress,
  }) async {
    if (filterType == FaceFilterType.none) return inputVideo;

    var resolved = track;
    var ownsTrack = false;
    if (resolved == null) {
      resolved = await analyzeVideo(
        inputVideo,
        onProgress: (p) => onProgress?.call(p * 0.45),
      );
      ownsTrack = resolved != null;
    }

    if (resolved != null && resolved.hasAnyFace) {
      onProgress?.call(0.5);
      final burned = await _burnTrackedFrames(
        inputVideo: inputVideo,
        track: resolved,
        filterAssets: filterAssets,
        filterType: filterType,
        onProgress: onProgress,
      );
      if (ownsTrack) await resolved.dispose();
      if (burned != null) return burned;
    } else if (ownsTrack) {
      await resolved?.dispose();
    }

    // Si el tracking falla, al menos quemar el filtro del primer frame.
    return _applyStaticFallback(
      inputVideo: inputVideo,
      filterAssets: filterAssets,
      filterType: filterType,
      faces: faces,
      videoWidth: videoWidth,
      videoHeight: videoHeight,
      frameSize: frameSize ?? resolved?.frameSize,
      mirror: mirror,
    );
  }

  static Future<File?> _burnTrackedFrames({
    required File inputVideo,
    required VideoFaceTrack track,
    required FaceFilterAssets filterAssets,
    required FaceFilterType filterType,
    void Function(double progress)? onProgress,
  }) async {
    final sources = _sortedPngs(track.framesDir);
    if (sources.isEmpty) return null;

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final filteredDir =
        Directory('${Directory.systemTemp.path}/vf_filtered_$stamp');
    await filteredDir.create(recursive: true);

    try {
      final count = math.min(sources.length, track.facesPerFrame.length);
      for (var i = 0; i < count; i++) {
        final dest = File(
          '${filteredDir.path}/frame_${(i + 1).toString().padLeft(5, '0')}.png',
        );
        await _writeFilteredFrame(
          source: sources[i],
          dest: dest,
          faces: track.facesPerFrame[i],
          assets: filterAssets,
          filterType: filterType,
        );
        onProgress?.call(0.5 + 0.35 * ((i + 1) / count));
      }

      final outputFile = File(
        '${Directory.systemTemp.path}/filtered_video_$stamp.mp4',
      );

      final encoded = await _encodeFrameSequence(
        framesDir: filteredDir,
        inputVideo: inputVideo,
        outputVideo: outputFile,
        fps: track.fps,
      );
      onProgress?.call(1);
      if (encoded && await outputFile.exists()) return outputFile;
      return null;
    } finally {
      await deleteDir(filteredDir);
    }
  }

  static Future<void> _writeFilteredFrame({
    required File source,
    required File dest,
    required List<Face> faces,
    required FaceFilterAssets assets,
    required FaceFilterType filterType,
  }) async {
    if (faces.isEmpty || filterType == FaceFilterType.none) {
      await source.copy(dest.path);
      return;
    }

    final bytes = await source.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImage(image, Offset.zero, Paint());
    for (final face in faces) {
      paintFilterOnFace(
        canvas: canvas,
        face: face,
        assets: assets,
        filterType: filterType,
      );
    }

    final rendered =
        await recorder.endRecording().toImage(image.width, image.height);
    final png = await rendered.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    rendered.dispose();

    if (png == null) {
      await source.copy(dest.path);
      return;
    }
    await dest.writeAsBytes(png.buffer.asUint8List());
  }

  static Future<bool> _encodeFrameSequence({
    required Directory framesDir,
    required File inputVideo,
    required File outputVideo,
    required int fps,
  }) async {
    final pattern = '${framesDir.path}/frame_%05d.png';
    final fpsLabel = fps.toString();

    final withAudio = await _run([
      '-y',
      '-framerate',
      fpsLabel,
      '-i',
      pattern,
      '-i',
      inputVideo.path,
      '-map',
      '0:v:0',
      '-map',
      '1:a:0?',
      '-c:v',
      'libx264',
      '-preset',
      'ultrafast',
      '-crf',
      '23',
      '-pix_fmt',
      'yuv420p',
      '-c:a',
      'aac',
      '-r',
      '30',
      '-shortest',
      '-movflags',
      '+faststart',
      outputVideo.path,
    ]);
    if (withAudio) return true;

    return _run([
      '-y',
      '-framerate',
      fpsLabel,
      '-i',
      pattern,
      '-c:v',
      'libx264',
      '-preset',
      'ultrafast',
      '-crf',
      '23',
      '-pix_fmt',
      'yuv420p',
      '-an',
      '-r',
      '30',
      '-movflags',
      '+faststart',
      outputVideo.path,
    ]);
  }

  static Future<File> _applyStaticFallback({
    required File inputVideo,
    required FaceFilterAssets filterAssets,
    required FaceFilterType filterType,
    required List<Face> faces,
    int? videoWidth,
    int? videoHeight,
    Size? frameSize,
    required bool mirror,
  }) async {
    var resolvedFaces = faces;
    var resolvedFrameSize = frameSize;
    File? tempFrame;

    if (resolvedFaces.isEmpty || resolvedFrameSize == null) {
      tempFrame = await extractFirstFrame(inputVideo);
      if (tempFrame == null) return inputVideo;
      resolvedFrameSize ??= await _imageSize(tempFrame);
      if (resolvedFaces.isEmpty) {
        final detector = FaceDetector(
          options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.accurate,
            enableLandmarks: true,
          ),
        );
        try {
          resolvedFaces =
              await detector.processImage(InputImage.fromFile(tempFrame));
        } finally {
          await detector.close();
        }
      }
    }

    if (resolvedFaces.isEmpty || resolvedFrameSize == null) {
      if (tempFrame != null) {
        try {
          await tempFrame.delete();
        } catch (_) {}
      }
      return inputVideo;
    }

    final width = videoWidth ?? resolvedFrameSize.width.round();
    final height = videoHeight ?? resolvedFrameSize.height.round();
    final overlay = await renderFilterOverlay(
      faces: resolvedFaces,
      filterAssets: filterAssets,
      filterType: filterType,
      videoWidth: width,
      videoHeight: height,
      frameSize: resolvedFrameSize,
      mirror: mirror,
    );

    if (tempFrame != null) {
      try {
        await tempFrame.delete();
      } catch (_) {}
    }
    if (overlay == null) return inputVideo;

    final outputFile = File(
      '${Directory.systemTemp.path}'
      '/filtered_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );
    final ok = await burnFilterIntoVideo(
      inputVideo: inputVideo,
      overlayPng: overlay,
      outputVideo: outputFile,
    );
    try {
      await overlay.delete();
    } catch (_) {}
    if (ok && await outputFile.exists()) return outputFile;
    return inputVideo;
  }

  static int _trackingFpsFor(double durationSeconds) {
    if (durationSeconds <= 0) return 8;
    final fps = (_maxTrackedFrames / durationSeconds).floor();
    return fps.clamp(6, _maxTrackingFps);
  }

  static Future<double> _probeDuration(File videoFile) async {
    try {
      final session = await FFprobeKit.getMediaInformation(videoFile.path);
      final info = session.getMediaInformation();
      return double.tryParse(info?.getDuration() ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<bool> _extractFrames(
    File videoFile,
    Directory outputDir,
    int fps,
  ) async {
    return _run([
      '-y',
      '-i',
      videoFile.path,
      '-vf',
      'fps=$fps,scale=720:-2',
      '${outputDir.path}/frame_%05d.png',
    ]);
  }

  static List<File> _sortedPngs(Directory dir) {
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.png'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  static Future<Size?> _imageSize(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final size = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> _run(List<String> args) async {
    final session = await FFmpegKit.executeWithArguments(args);
    final code = await session.getReturnCode();
    if (ReturnCode.isSuccess(code)) return true;
    final output = await session.getOutput();
    debugPrint('FFmpeg failed (${code?.getValue()}): ${args.join(' ')}');
    debugPrint(output);
    return false;
  }

  static Future<void> deleteDir(Directory dir) async {
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }
}
