import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toktok/domain/entities/video_post.dart';

class VideoRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collection = 'videos';

  /// Guarda los metadatos del archivo en Firestore.
  /// [isVideo] indica si es video (true) o imagen (false).
  /// Devuelve el ID del documento creado.
  Future<String> saveVideo({
    required String cloudinaryUrl,
    required String caption,
    String? userId,
    String? thumbnailUrl,
    bool isVideo = true,
  }) async {
    final docRef = await _db.collection(_collection).add({
      'cloudinaryUrl': cloudinaryUrl,
      'caption': caption,
      'userId': userId ?? 'anonimo',
      'thumbnailUrl': thumbnailUrl ?? '',
      'isVideo': isVideo,
      'likes': 0,
      'views': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Obtiene todos los videos ordenados por fecha de creación.
  Future<List<VideoPost>> getVideos() async {
    final snapshot = await _db
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return VideoPost(
        id: doc.id,
        caption: data['caption'] ?? '',
        videoUrl: data['cloudinaryUrl'] ?? '',
        thumbnailUrl: data['thumbnailUrl'],
        userId: data['userId'],
        likes: (data['likes'] ?? 0) as int,
        views: (data['views'] ?? 0) as int,
        isVideo: data['isVideo'] ?? true,
      );
    }).toList();
  }

  /// Incrementa el contador de likes de un video.
  Future<void> toggleLike(String videoId) async {
    await _db.collection(_collection).doc(videoId).update({
      'likes': FieldValue.increment(1),
    });
  }

  /// Incrementa el contador de vistas.
  Future<void> incrementViews(String videoId) async {
    await _db.collection(_collection).doc(videoId).update({
      'views': FieldValue.increment(1),
    });
  }
}
