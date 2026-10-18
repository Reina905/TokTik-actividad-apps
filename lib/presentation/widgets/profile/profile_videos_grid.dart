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
            Text('Todavía no hay videos',
                style: TextStyle(color: Colors.white54)),
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
        // Miniatura
        if (hasThumbnail)
          Image.network(
            thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _PlaceholderTile(),
          )
        else
          const _PlaceholderTile(),

        // Gradiente inferior para que se lean las vistas
        VideoBackground(stops: const [0.6, 1.0]),

        // Vistas
        Positioned(
          left: 6,
          bottom: 6,
          child: Row(
            children: [
              const Icon(Icons.play_arrow_outlined,
                  size: 16, color: Colors.white),
              const SizedBox(width: 2),
              Text(
                HumanFormats.humanReadbleNumber(video.views.toDouble()),
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
  const _PlaceholderTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white10,
      child: const Icon(Icons.play_circle_outline,
          color: Colors.white38, size: 36),
    );
  }
}
