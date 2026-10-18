import 'package:flutter/material.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/presentation/widgets/shared/video_page_with_profile.dart';

class VideoScrollableView extends StatelessWidget {
  final List<VideoPost> videos;

  /// Opcional: se llama cuando el usuario está a 2 videos del final.
  /// Quien no lo use (Discover) se comporta igual que antes.
  final VoidCallback? onNearEnd;

  const VideoScrollableView({
    super.key,
    required this.videos,
    this.onNearEnd,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      itemCount: videos.length,
      onPageChanged: (index) {
        if (onNearEnd != null && index >= videos.length - 2) {
          onNearEnd!();
        }
      },
      itemBuilder: (context, index) {
        final VideoPost videoPost = videos[index];

        // Cada video puede deslizarse a la izquierda para ver el perfil de su autor
        return VideoPageWithProfile(videoPost: videoPost);
      },
    );
  }
}
