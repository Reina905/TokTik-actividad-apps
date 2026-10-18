import 'package:toktok/domain/datasources/profile_datasource.dart';
import 'package:toktok/domain/entities/user_profile.dart';
import 'package:toktok/domain/entities/video_post.dart';

class ProfileRepository {
  final ProfileDataSource dataSource;

  ProfileRepository({required this.dataSource});

  Future<UserProfile?> getProfileByUid(String uid) {
    return dataSource.getProfileByUid(uid);
  }

  Future<List<VideoPost>> getVideosByUser(String uid) {
    return dataSource.getVideosByUser(uid);
  }

  Future<bool> isFollowing({
    required String currentUid,
    required String targetUid,
  }) {
    return dataSource.isFollowing(currentUid: currentUid, targetUid: targetUid);
  }

  Future<void> follow({
    required String currentUid,
    required String targetUid,
  }) {
    return dataSource.follow(currentUid: currentUid, targetUid: targetUid);
  }

  Future<void> unfollow({
    required String currentUid,
    required String targetUid,
  }) {
    return dataSource.unfollow(currentUid: currentUid, targetUid: targetUid);
  }
}
