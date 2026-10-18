import 'package:flutter/material.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/infrastructure/repositories/video_repository.dart';

class DiscoverProvider extends ChangeNotifier {
  final VideoRepository _videoRepository = VideoRepository();

  bool initialLoading = true;
  List<VideoPost> videos = [];
  String? errorMessage;

  /// Carga los videos desde Firestore (URLs de Cloudinary).
  Future<void> loadNextPage() async {
    try {
      videos = await _videoRepository.getVideos();
    } catch (e) {
      errorMessage = 'No se pudieron cargar los videos';
    }
    initialLoading = false;
    notifyListeners();
  }

  /// Reintenta la carga desde Firestore.
  Future<void> reload() async {
    initialLoading = true;
    errorMessage = null;
    notifyListeners();
    await loadNextPage();
  }
}
