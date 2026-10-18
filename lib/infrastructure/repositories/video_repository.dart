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
  static const String _likesSubcollection = 'likes';

  Future<String> saveVideo({
    required String cloudinaryUrl,
    required String caption,
    String? userId,
    String? userName,
    String? thumbnailUrl,
    bool isVideo = true,
  }) async {
    final docRef = await _db.collection(_collection).add({
      'cloudinaryUrl': cloudinaryUrl,
      'caption': caption,
      'userId': userId ?? 'anonimo',
      'userName': userName ?? '',
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
    final rawUserName = data['userName'];
    return VideoPost(
      id: doc.id,
      caption: data['caption'] ?? '',
      videoUrl: data['cloudinaryUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      userId: data['userId'],
      userName: (rawUserName is String && rawUserName.isNotEmpty)
          ? rawUserName
          : null,
      likes: (data['likes'] ?? 0) as int,
      views: (data['views'] ?? 0) as int,
      isVideo: data['isVideo'] ?? true,
    );
  }

  /// Likes en videos/{videoId}/likes/{uid}.
  Future<({bool liked, int likes})> getLikeStatus({
    required String videoId,
    String? uid,
  }) async {
    final videoRef = _db.collection(_collection).doc(videoId);

    final results = await Future.wait([
      videoRef.get(),
      if (uid != null) videoRef.collection(_likesSubcollection).doc(uid).get(),
    ]);

    return (
      liked: uid != null && results[1].exists,
      likes: (results[0].data()?['likes'] ?? 0) as int,
    );
  }

  /// Devuelve `true` si el video quedó con like.
  Future<bool> toggleLike({
    required String videoId,
    required String uid,
  }) {
    final videoRef = _db.collection(_collection).doc(videoId);
    final likeRef = videoRef.collection(_likesSubcollection).doc(uid);

    return _db.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);

      if (likeDoc.exists) {
        transaction.delete(likeRef);
        transaction.update(videoRef, {'likes': FieldValue.increment(-1)});
        return false;
      }

      transaction.set(likeRef, {
        'userId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(videoRef, {'likes': FieldValue.increment(1)});
      return true;
    });
  }

  Future<void> incrementViews(String videoId) async {
    await _db.collection(_collection).doc(videoId).update({
      'views': FieldValue.increment(1),
    });
  }
}
