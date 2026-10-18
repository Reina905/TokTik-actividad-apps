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

  const CreatorProfileScreen({
    super.key,
    required this.uid,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    // Un ProfileProvider nuevo por cada perfil que se abre
    return ChangeNotifierProvider(
      create: (context) => ProfileProvider(
        repository: context.read<ProfileRepository>(),
        uid: uid,
      )..loadProfile(currentUid: context.read<AuthProvider>().userId),
      child: _CreatorProfileView(onBack: onBack),
    );
  }
}

class _CreatorProfileView extends StatelessWidget {
  final VoidCallback? onBack;

  const _CreatorProfileView({this.onBack});

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: onBack ?? () => Navigator.maybePop(context),
        ),
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
