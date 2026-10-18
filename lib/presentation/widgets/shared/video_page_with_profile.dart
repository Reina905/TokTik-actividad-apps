import 'package:flutter/material.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/presentation/screens/profile/creator_profile_screen.dart';
import 'package:toktok/presentation/widgets/shared/video_buttons.dart';
import 'package:toktok/presentation/widgets/video/fullscreen_player.dart';
import 'package:toktok/presentation/widgets/video/video_background.dart';

/// Un video del feed. Si tiene autor, al deslizar a la izquierda
/// se abre el perfil del creador
class VideoPageWithProfile extends StatefulWidget {
  final VideoPost videoPost;

  const VideoPageWithProfile({
    super.key,
    required this.videoPost,
  });

  @override
  State<VideoPageWithProfile> createState() => _VideoPageWithProfileState();
}

class _VideoPageWithProfileState extends State<VideoPageWithProfile> {
  final PageController _pageController = PageController();

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoPost = widget.videoPost;
    final authorUid = videoPost.userId ?? '';
    final hasAuthor = authorUid.isNotEmpty;

    // Misma estructura que tenía cada página de VideoScrollableView
    final videoPage = Stack(
      children: [
        // Video Player o imagen + gradiente
        SizedBox.expand(
          child: videoPost.isVideo
              ? FullScreenPlayer(
                  caption: videoPost.caption,
                  videoUrl: videoPost.videoUrl,
                )
              : Image.network(
                  videoPost.videoUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image,
                        color: Colors.white54, size: 48),
                  ),
                ),
        ),

        // Gradiente para que se lea el caption en imágenes
        if (!videoPost.isVideo)
          VideoBackground(stops: const [0.7, 1.0]),

        // Botones
        Positioned(
          bottom: 40,
          right: 20,
          child: VideoButtons(
            video: videoPost,
            onProfileTap: hasAuthor ? () => _goToPage(1) : null,
          ),
        ),
      ],
    );

    // Videos sin autor, subidos como 'anonimo': solo el video, sin perfil
    if (!hasAuthor) return videoPage;

    return PageView(
      controller: _pageController,
      children: [
        videoPage,
        CreatorProfileScreen(
          uid: authorUid,
          onBack: () => _goToPage(0),
        ),
      ],
    );
  }
}
