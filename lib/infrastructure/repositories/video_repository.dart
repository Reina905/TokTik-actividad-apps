import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toktok/domain/entities/video_post.dart';

class VideoPage {
  final List<VideoPost> videos;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;

  VideoPage({
    required this.videos,
    required this.lastDoc,
    required this.hasMore,
  });
}

class VideoRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collection = 'videos';

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

  Future<List<VideoPost>> getVideos() async {
    final snapshot = await _db
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => _docToVideoPost(doc)).toList();
  }

  
  Future<VideoPage> getVideosPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 5,
  }) async {
    var query = _db
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();

    return VideoPage(
      videos: snapshot.docs.map((doc) => _docToVideoPost(doc)).toList(),
      lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : startAfter,
      hasMore: snapshot.docs.length == limit,
    );
  }

  Future<List<VideoPost>> getVideosByUser(String uid) async {
    final snapshot = await _db
        .collection(_collection)
        .where('userId', isEqualTo: uid)
        .get();

    final docs = snapshot.docs.toList();
    docs.sort((a, b) {
      final aTime = a.data()['createdAt'];
      final bTime = b.data()['createdAt'];
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return (bTime as Timestamp).compareTo(aTime as Timestamp);
    });

    return docs.map((doc) => _docToVideoPost(doc)).toList();
  }

  VideoPost _docToVideoPost(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
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
  }

  Future<void> toggleLike(String videoId) async {
    await _db.collection(_collection).doc(videoId).update({
      'likes': FieldValue.increment(1),
    });
  }

  Future<void> incrementViews(String videoId) async {
    await _db.collection(_collection).doc(videoId).update({
      'views': FieldValue.increment(1),
    });
  }
}
