import 'package:toktok/domain/entities/video_post.dart';

class LocalVideoModel {
  final String name;
  final String videoUrl;
  final String authorUid;
  final int likes;
  final int views;

  LocalVideoModel({
    required this.name,
    required this.videoUrl,
    required this.authorUid,
    this.likes = 0,
    this.views = 0,
  });

  factory LocalVideoModel.fromJson(Map<String, dynamic> json) =>
      LocalVideoModel(
        name: json['name'] ?? 'No name',
        videoUrl: json['videoUrl'],
        authorUid: json['authorUid'] ?? '',
        likes: json['likes'] ?? 0,
        views: json['views'] ?? 0,
      );

  VideoPost toVideoPostEntity() => VideoPost(
    caption: name,
    videoUrl: videoUrl,
    authorUid: authorUid,
    likes: likes,
    views: views,
  );
}
