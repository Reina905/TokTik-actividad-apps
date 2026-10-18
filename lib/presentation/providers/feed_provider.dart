import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/infrastructure/repositories/video_repository.dart';

class FeedProvider extends ChangeNotifier {
  final VideoRepository _repository;

  FeedProvider({VideoRepository? repository})
      : _repository = repository ?? VideoRepository();

  bool initialLoading = true;
  String? error;
  List<VideoPost> videos = [];

  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;

  Future<void> loadNextPage() async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;

    try {
      final page = await _repository.getVideosPage(startAfter: _lastDoc);

      videos.addAll(page.videos.where((v) => v.videoUrl.isNotEmpty));
      _lastDoc = page.lastDoc;
      _hasMore = page.hasMore;
      error = null;
    } catch (e) {
      debugPrint('Error cargando feed: $e');
      error = 'No se pudo cargar el feed';
    } finally {
      _isLoading = false;
      initialLoading = false;
      notifyListeners();
    }
  }

  /// Para el botón "Reintentar".
  Future<void> refresh() async {
    videos = [];
    _lastDoc = null;
    _hasMore = true;
    error = null;
    initialLoading = true;
    notifyListeners();
    await loadNextPage();
  }
}
