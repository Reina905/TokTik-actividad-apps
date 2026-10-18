import 'dart:io';
import 'package:flutter/material.dart';
import 'package:toktok/infrastructure/repositories/video_repository.dart';
import 'package:toktok/infrastructure/services/cloudinary_service.dart';

enum UploadStatus { idle, uploading, success, error }

class UploadVideoProvider extends ChangeNotifier {
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final VideoRepository _videoRepository = VideoRepository();

  UploadStatus _status = UploadStatus.idle;
  double _progress = 0;
  String? _errorMessage;

  UploadStatus get status => _status;
  double get progress => _progress;
  String? get errorMessage => _errorMessage;
  bool get isUploading => _status == UploadStatus.uploading;

  /// Sube el archivo a Cloudinary y guarda los metadatos en Firestore.
  /// El thumbnail se genera automáticamente a partir de la URL de Cloudinary
  /// sin necesidad de librerías de procesamiento de video.
  Future<bool> uploadFile({
    required File file,
    required String caption,
    required bool isVideo,
    String? userId,
    String? userName,
    String? thumbnailUrl, // opcional; si null, se calcula desde cloudinaryUrl
  }) async {
    try {
      _status = UploadStatus.uploading;
      _progress = 0;
      _errorMessage = null;
      notifyListeners();

      // 1. Subir archivo principal a Cloudinary
      _progress = 0.3;
      notifyListeners();

      final cloudinaryUrl = await _cloudinaryService.uploadFile(
        file,
        type: isVideo
            ? CloudinaryResourceType.video
            : CloudinaryResourceType.image,
      );

      _progress = 0.8;
      notifyListeners();

      // 2. Calcular thumbnail URL si no se proporcionó externamente
      final resolvedThumbnail =
          thumbnailUrl ?? _thumbnailUrl(cloudinaryUrl, isVideo);

      // 3. Guardar metadatos en Firestore
      await _videoRepository.saveVideo(
        cloudinaryUrl: cloudinaryUrl,
        caption: caption,
        isVideo: isVideo,
        userId: userId,
        userName: userName,
        thumbnailUrl: resolvedThumbnail,
      );

      _progress = 1.0;
      _status = UploadStatus.success;
      notifyListeners();

      return true;
    } catch (e) {
      _status = UploadStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Genera la URL del thumbnail a partir de una URL de Cloudinary.
  ///
  /// Para videos: Cloudinary genera el thumbnail del primer frame
  /// insertando una transformación y cambiando la extensión a .jpg.
  ///   .../upload/v123/video.mp4
  ///   → .../upload/so_0,w_480,c_scale/v123/video.jpg
  ///
  /// Para fotos: la propia URL de la imagen sirve como thumbnail.
  static String? _thumbnailUrl(String cloudinaryUrl, bool isVideo) {
    if (!isVideo) return cloudinaryUrl;
    try {
      final uri = Uri.parse(cloudinaryUrl);
      final segments = List<String>.from(uri.pathSegments);

      final uploadIdx = segments.indexOf('upload');
      if (uploadIdx == -1) return null;

      // Insertar transformación de Cloudinary después de "upload"
      segments.insert(uploadIdx + 1, 'so_0,w_480,c_scale');

      // Cambiar extensión del archivo a .jpg
      final last = segments.last;
      final dot = last.lastIndexOf('.');
      segments[segments.length - 1] =
          dot != -1 ? '${last.substring(0, dot)}.jpg' : '$last.jpg';

      return uri.replace(pathSegments: segments).toString();
    } catch (_) {
      return null;
    }
  }

  void reset() {
    _status = UploadStatus.idle;
    _progress = 0;
    _errorMessage = null;
    notifyListeners();
  }
}
