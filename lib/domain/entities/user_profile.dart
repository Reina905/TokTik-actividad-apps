class UserProfile {
  final String uid;
  final String name;
  final String username;
  final String bio;
  final String? photoUrl;
  final int following;
  final int followers;
  final int likes;

  UserProfile({
    required this.uid,
    required this.name,
    required this.username,
    this.bio = '',
    this.photoUrl,
    this.following = 0,
    this.followers = 0,
    this.likes = 0,
  });
}
