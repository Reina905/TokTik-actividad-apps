import 'package:toktok/domain/entities/user_profile.dart';
import 'package:toktok/domain/entities/video_post.dart';

abstract class ProfileDataSource {
  Future<UserProfile?> getProfileByUid(String uid);

  Future<List<VideoPost>> getVideosByUser(String uid);

  Future<bool> isFollowing({
    required String currentUid,
    required String targetUid,
  });

  Future<void> follow({
    required String currentUid,
    required String targetUid,
  });

  Future<void> unfollow({
    required String currentUid,
    required String targetUid,
  });
}
