import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/infrastructure/repositories/profile_repository.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';
import 'package:toktok/presentation/providers/profile_provider.dart';
import 'package:toktok/presentation/widgets/auth/auth_popup.dart';
import 'package:toktok/presentation/widgets/profile/profile_header.dart';
import 'package:toktok/presentation/widgets/profile/profile_videos_grid.dart';

class CreatorProfileScreen extends StatelessWidget {
  final String uid;

  // Qué hacer al tocar atras
  final VoidCallback? onBack;

  // Mostrar o no el botón de retroceso. Cuando se abre desde el
  // navbar (mi perfil) no aplica volver; desde un video sí.
  final bool showBackButton;

  // Nombre de respaldo para crear un perfil por defecto cuando no
  // existe en la fuente de datos (perfil propio desde el navbar).
  final String? fallbackName;

  const CreatorProfileScreen({
    super.key,
    required this.uid,
    this.onBack,
    this.showBackButton = true,
    this.fallbackName,
  });

  @override
  Widget build(BuildContext context) {
    // Un ProfileProvider nuevo por cada perfil que se abre
    return ChangeNotifierProvider(
      create: (context) => ProfileProvider(
        repository: context.read<ProfileRepository>(),
        uid: uid,
      )..loadProfile(
          currentUid: context.read<AuthProvider>().userId,
          fallbackName: fallbackName,
        ),
      child: _CreatorProfileView(
        onBack: onBack,
        showBackButton: showBackButton,
      ),
    );
  }
}

class _CreatorProfileView extends StatelessWidget {
  final VoidCallback? onBack;
  final bool showBackButton;

  const _CreatorProfileView({
    this.onBack,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        automaticallyImplyLeading: showBackButton,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: onBack ?? () => Navigator.maybePop(context),
              )
            : null,
        // Botón de cerrar sesión solo en el perfil propio (navbar)
        actions: showBackButton
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.logout, size: 22),
                  onPressed: () => context.read<AuthProvider>().logout(),
                ),
              ],
        title: Text(
          profile?.name ?? '',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: _buildBody(profileProvider),
    );
  }

  Widget _buildBody(ProfileProvider profileProvider) {
    if (profileProvider.initialLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final profile = profileProvider.profile;

    if (profile == null) {
      return Center(
        child: Text(
          profileProvider.errorMessage ?? 'Perfil no disponible',
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView(
      children: [
        ProfileHeader(
          profile: profile,
          actionButton: const _FollowButton(),
        ),
        const _VideosTabBar(),
        ProfileVideosGrid(videos: profileProvider.videos),
      ],
    );
  }
}

// Botón Seguir o Editar perfil: lo decide la pantalla que usa este widget

class _FollowButton extends StatelessWidget {
  const _FollowButton();

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final authProvider = context.watch<AuthProvider>();

    // Si el perfil es el mío, no tiene sentido seguirme
    if (authProvider.userId == profileProvider.uid) {
      return const SizedBox.shrink();
    }

    final isFollowing = profileProvider.isFollowing;
    final buttonColor = isFollowing ? Colors.white12 : const Color(0xFFEE1D52);

    return SizedBox(
      width: 180,
      height: 44,
      child: FilledButton(
        onPressed: profileProvider.isFollowLoading
            ? null
            // Seguir requiere sesión: si no hay, se abre el pop-up de login
            : () => requireAuth(
                  context,
                  onAuthenticated: () => profileProvider.toggleFollow(
                    context.read<AuthProvider>().userId!,
                  ),
                ),
        style: FilledButton.styleFrom(
          backgroundColor: buttonColor,
          disabledBackgroundColor: buttonColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        child: profileProvider.isFollowLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(isFollowing ? 'Siguiendo' : 'Seguir'),
      ),
    );
  }
}

class _VideosTabBar extends StatelessWidget {
  const _VideosTabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: Colors.white, width: 2)),
              ),
              child: const Icon(Icons.grid_on, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
