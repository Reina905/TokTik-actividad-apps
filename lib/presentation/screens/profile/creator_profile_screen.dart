import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/infrastructure/repositories/profile_repository.dart';
import 'package:toktok/infrastructure/repositories/video_repository.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';
import 'package:toktok/presentation/providers/profile_provider.dart';
import 'package:toktok/presentation/widgets/auth/auth_popup.dart';
import 'package:toktok/presentation/widgets/profile/profile_header.dart';
import 'package:toktok/presentation/widgets/profile/profile_videos_grid.dart';

class CreatorProfileScreen extends StatefulWidget {
  final String uid;
  final VoidCallback? onBack;
  final bool showBackButton;
  final String? fallbackName;

  const CreatorProfileScreen({
    super.key,
    required this.uid,
    this.onBack,
    this.showBackButton = true,
    this.fallbackName,
  });

  @override
  State<CreatorProfileScreen> createState() => CreatorProfileScreenState();
}

class CreatorProfileScreenState extends State<CreatorProfileScreen> {
  late ProfileProvider _profileProvider;

  @override
  void initState() {
    super.initState();
    _profileProvider = ProfileProvider(
      repository: context.read<ProfileRepository>(),
      uid: widget.uid,
      videoRepository: context.read<VideoRepository>(),
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _profileProvider.dispose();
    super.dispose();
  }

  void _loadProfile() {
    _profileProvider.loadProfile(
      currentUid: context.read<AuthProvider>().userId,
      fallbackName: widget.fallbackName,
    );
  }

  /// Recarga el perfil completo desde Firestore.
  /// Se llama desde [ProfileScreen] cuando el usuario toca el tab de perfil.
  void reloadProfile() {
    _profileProvider.reload(
      currentUid: context.read<AuthProvider>().userId,
      fallbackName: widget.fallbackName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _profileProvider,
      child: _CreatorProfileView(
        onBack: widget.onBack,
        showBackButton: widget.showBackButton,
      ),
    );
  }
}

// ─── Vista del perfil ─────────────────────────────────────────────────────────

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
        // Cerrar sesión solo en mi perfil (sin botón de atrás)
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

// ─── Botón seguir ─────────────────────────────────────────────────────────────

class _FollowButton extends StatelessWidget {
  const _FollowButton();

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final authProvider = context.watch<AuthProvider>();

    // En mi propio perfil no aparece el botón
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: profileProvider.isFollowLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(isFollowing ? 'Siguiendo' : 'Seguir'),
      ),
    );
  }
}

// ─── Tab bar de videos ────────────────────────────────────────────────────────

class _VideosTabBar extends StatelessWidget {
  const _VideosTabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white, width: 2),
                ),
              ),
              child: const Icon(Icons.grid_on, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
