class VideoPost {
  final String? id; // ID del documento en Firestore
  final String caption;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? userId;
  final String? userName; // Nombre visible del creador (Firebase displayName)
  final int likes;
  final int views;
  final bool isVideo; // false = foto subida a Cloudinary

  VideoPost({
    this.id,
    required this.caption,
    required this.videoUrl,
    this.thumbnailUrl,
    this.userId,
    this.userName,
    this.likes = 0,
    this.views = 0,
    this.isVideo = true,
  });
}
