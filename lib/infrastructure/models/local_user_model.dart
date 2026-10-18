import 'package:toktok/domain/entities/user_profile.dart';

class LocalUserModel {
  final String uid;
  final String name;
  final String username;
  final String bio;
  final String? photoUrl;
  final int following;
  final int followers;
  final int likes;

  LocalUserModel({
    required this.uid,
    required this.name,
    required this.username,
    this.bio = '',
    this.photoUrl,
    this.following = 0,
    this.followers = 0,
    this.likes = 0,
  });

  factory LocalUserModel.fromJson(Map<String, dynamic> json) => LocalUserModel(
    uid: json['uid'],
    name: json['name'] ?? 'Sin nombre',
    username: json['username'] ?? 'usuario',
    bio: json['bio'] ?? '',
    photoUrl: json['photoUrl'],
    following: json['following'] ?? 0,
    followers: json['followers'] ?? 0,
    likes: json['likes'] ?? 0,
  );

  UserProfile toUserProfileEntity() => UserProfile(
    uid: uid,
    name: name,
    username: username,
    bio: bio,
    photoUrl: photoUrl,
    following: following,
    followers: followers,
    likes: likes,
  );
}
