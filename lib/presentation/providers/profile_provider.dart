import 'package:flutter/material.dart';
import 'package:toktok/domain/entities/user_profile.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/infrastructure/repositories/profile_repository.dart';
import 'package:toktok/infrastructure/repositories/video_repository.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository repository;
  final String uid; // uid del perfil que se está viendo
  final VideoRepository? videoRepository;

  ProfileProvider({
    required this.repository,
    required this.uid,
    this.videoRepository,
  });

  bool initialLoading = true;
  bool isFollowLoading = false;
  bool isFollowing = false;
  UserProfile? profile;
  List<VideoPost> videos = [];
  String? errorMessage;

  bool _isDisposed = false;

  /// Recarga el perfil completo (videos incluidos). Útil cuando el usuario
  /// regresa al tab de perfil después de publicar contenido nuevo.
  Future<void> reload({String? currentUid, String? fallbackName}) {
    return loadProfile(currentUid: currentUid, fallbackName: fallbackName);
  }

  Future<void> loadProfile({String? currentUid, String? fallbackName}) async {
    initialLoading = true;
    errorMessage = null;
    _notify();

    try {
      final result = await repository.getProfileByUid(uid);

      if (result == null) {
        // Usuario de Firebase que no está en los datos locales.
        // Se intentan cargar sus videos subidos desde Firestore.
        if (videoRepository != null) {
          final userVideos = await videoRepository!.getVideosByUser(uid);
          if (userVideos.isNotEmpty || fallbackName != null) {
            profile = UserProfile(
              uid: uid,
              name: fallbackName ?? 'Usuario',
              username: _usernameFromName(fallbackName ?? 'usuario'),
              bio: '',
              following: 0,
              followers: 0,
              likes: userVideos.fold(0, (total, v) => total + v.likes),
            );
            videos = userVideos;
          } else {
            errorMessage = 'Este usuario no existe';
          }
        } else if (fallbackName != null) {
          profile = UserProfile(
            uid: uid,
            name: fallbackName,
            username: _usernameFromName(fallbackName),
            bio: '',
            following: 0,
            followers: 0,
            likes: 0,
          );
          videos = [];
        } else {
          errorMessage = 'Este usuario no existe';
        }
      } else {
        // Creador local: sus videos vienen de los datos locales
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

  /// Convierte un nombre para usarlo como username (minúsculas, sin espacios)
  String _usernameFromName(String name) {
    final username = name.toLowerCase().trim().replaceAll(' ', '_');
    return username.isEmpty ? 'usuario' : username;
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
