class VideoPost {
  final String caption;
  final String videoUrl;
  final String authorUid;
  final int likes;
  final int views;

  VideoPost(
      {required this.caption,
      required this.videoUrl,
      required this.authorUid,
      this.likes = 0,
      this.views = 0});
}
