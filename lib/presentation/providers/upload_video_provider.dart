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

  /// Sube el archivo (video o imagen) a Cloudinary y guarda los metadatos en Firestore.
  Future<bool> uploadFile({
    required File file,
    required String caption,
    required bool isVideo,
    String? userId,
  }) async {
    try {
      _status = UploadStatus.uploading;
      _progress = 0;
      _errorMessage = null;
      notifyListeners();

      // 1. Subir a Cloudinary
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

      // 2. Guardar metadatos en Firestore
      await _videoRepository.saveVideo(
        cloudinaryUrl: cloudinaryUrl,
        caption: caption,
        isVideo: isVideo,
        userId: userId,
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

  void reset() {
    _status = UploadStatus.idle;
    _progress = 0;
    _errorMessage = null;
    notifyListeners();
  }
}
