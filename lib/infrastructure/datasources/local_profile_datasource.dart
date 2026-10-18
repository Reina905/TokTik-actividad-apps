import 'package:toktok/domain/datasources/profile_datasource.dart';
import 'package:toktok/domain/entities/user_profile.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/infrastructure/models/local_user_model.dart';
import 'package:toktok/infrastructure/models/local_video_model.dart';
import 'package:toktok/shared/data/local_users.dart';
import 'package:toktok/shared/data/local_video_posts.dart';

class LocalProfileDataSource implements ProfileDataSource {
  // Relaciones "quién sigue a quién", solo en memoria: se pierden al cerrar la app
  final Set<String> _follows = {};

  String _key(String currentUid, String targetUid) => '$currentUid->$targetUid';

  Map<String, dynamic>? _findUser(String uid) {
    for (final user in localUsers) {
      if (user['uid'] == uid) return user;
    }
    return null;
  }

  void _changeFollowers(String uid, int amount) {
    final user = _findUser(uid);
    if (user == null) return;
    user['followers'] = (user['followers'] ?? 0) + amount;
  }

  @override
  Future<UserProfile?> getProfileByUid(String uid) async {
    final user = _findUser(uid);
    if (user == null) return null;

    return LocalUserModel.fromJson(user).toUserProfileEntity();
  }

  @override
  Future<List<VideoPost>> getVideosByUser(String uid) async {
    return videoPosts
        .where((video) => video['userId'] == uid)
        .map((video) => LocalVideoModel.fromJson(video).toVideoPostEntity())
        .toList();
  }

  @override
  Future<bool> isFollowing({
    required String currentUid,
    required String targetUid,
  }) async {
    return _follows.contains(_key(currentUid, targetUid));
  }

  @override
  Future<void> follow({
    required String currentUid,
    required String targetUid,
  }) async {
    // add devuelve false si ya lo seguía: así no se cuenta dos veces
    final added = _follows.add(_key(currentUid, targetUid));
    if (!added) return;

    _changeFollowers(targetUid, 1);
  }

  @override
  Future<void> unfollow({
    required String currentUid,
    required String targetUid,
  }) async {
    // remove devuelve false si no lo seguía: así no se resta de más
    final removed = _follows.remove(_key(currentUid, targetUid));
    if (!removed) return;

    _changeFollowers(targetUid, -1);
  }
}
