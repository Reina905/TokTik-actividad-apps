import 'package:flutter/material.dart';
import 'package:toktok/config/helpers/human_formats.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/presentation/widgets/video/video_background.dart';

class ProfileVideosGrid extends StatelessWidget {
  final List<VideoPost> videos;

  const ProfileVideosGrid({super.key, required this.videos});

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.videocam_off_outlined, size: 48, color: Colors.white38),
            SizedBox(height: 12),
            Text(
              'Todavía no hay publicaciones',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: videos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 3 / 4,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemBuilder: (context, index) => _VideoTile(video: videos[index]),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final VideoPost video;

  const _VideoTile({required this.video});

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = video.thumbnailUrl;
    final hasThumbnail = thumbnailUrl != null && thumbnailUrl.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Miniatura ─────────────────────────────────────────────────────
        if (hasThumbnail)
          Image.network(
            thumbnailUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _PlaceholderTile(isVideo: video.isVideo);
            },
            errorBuilder: (_, __, ___) =>
                _PlaceholderTile(isVideo: video.isVideo),
          )
        else
          _PlaceholderTile(isVideo: video.isVideo),

        // ── Gradiente inferior ────────────────────────────────────────────
        VideoBackground(stops: const [0.55, 1.0]),

        // ── Insignia de video (ícono de play en la esquina superior) ──────
        if (video.isVideo)
          const Positioned(
            top: 6,
            right: 6,
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 18,
              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),

        // ── Vistas ────────────────────────────────────────────────────────
        Positioned(
          left: 6,
          bottom: 6,
          child: Row(
            children: [
              Icon(
                video.isVideo
                    ? Icons.play_arrow_outlined
                    : Icons.favorite_outline,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 2),
              Text(
                HumanFormats.humanReadbleNumber(
                  (video.isVideo ? video.views : video.likes).toDouble(),
                ),
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaceholderTile extends StatelessWidget {
  final bool isVideo;
  const _PlaceholderTile({required this.isVideo});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white10,
      child: Center(
        child: Icon(
          isVideo
              ? Icons.play_circle_outline
              : Icons.image_outlined,
          color: Colors.white24,
          size: 36,
        ),
      ),
    );
  }
}
