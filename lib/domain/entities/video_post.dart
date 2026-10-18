class VideoPost {
  final String? id; // ID del documento en Firestore
  final String caption;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? userId;
  final int likes;
  final int views;

  VideoPost({
    this.id,
    required this.caption,
    required this.videoUrl,
    this.thumbnailUrl,
    this.userId,
    this.likes = 0,
    this.views = 0,
  });
}
