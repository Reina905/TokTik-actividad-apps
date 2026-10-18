import 'package:flutter/material.dart';
import 'package:toktok/domain/entities/user_profile.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/infrastructure/repositories/profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository repository;
  final String uid; // uid del perfil que se está viendo

  ProfileProvider({
    required this.repository,
    required this.uid,
  });

  bool initialLoading = true;
  bool isFollowLoading = false;
  bool isFollowing = false;
  UserProfile? profile;
  List<VideoPost> videos = [];
  String? errorMessage;

  bool _isDisposed = false;

  Future<void> loadProfile({String? currentUid}) async {
    initialLoading = true;
    errorMessage = null;
    _notify();

    try {
      final result = await repository.getProfileByUid(uid);

      if (result == null) {
        errorMessage = 'Este usuario no existe';
      } else {
        profile = result;
        videos = await repository.getVideosByUser(uid);
        isFollowing = await _checkFollowing(currentUid);
      }
    } catch (_) {
      errorMessage = 'No se pudo cargar el perfil';
    }

    initialLoading = false;
    _notify();
  }

  Future<void> toggleFollow(String currentUid) async {
    // Evita doble toque y que alguien se siga a sí mismo
    if (isFollowLoading || currentUid == uid) return;

    isFollowLoading = true;
    _notify();

    try {
      if (isFollowing) {
        await repository.unfollow(currentUid: currentUid, targetUid: uid);
      } else {
        await repository.follow(currentUid: currentUid, targetUid: uid);
      }

      isFollowing = !isFollowing;

      // Se vuelve a leer el perfil para mostrar el contador real de seguidores
      profile = await repository.getProfileByUid(uid) ?? profile;
    } catch (_) {
      errorMessage = 'No se pudo actualizar. Inténtalo de nuevo';
    }

    isFollowLoading = false;
    _notify();
  }

  Future<bool> _checkFollowing(String? currentUid) async {
    // Sin sesión, o viendo mi propio perfil: no aplica "seguir"
    if (currentUid == null || currentUid == uid) return false;

    return repository.isFollowing(currentUid: currentUid, targetUid: uid);
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
