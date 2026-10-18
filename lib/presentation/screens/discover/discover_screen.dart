import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/presentation/providers/discover_provider.dart';
import 'package:toktok/presentation/widgets/shared/video_scrollable_view.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final discoverProvider = context.watch<DiscoverProvider>();

    if (discoverProvider.initialLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (discoverProvider.errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.white54),
              const SizedBox(height: 12),
              Text(
                discoverProvider.errorMessage!,
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => discoverProvider.reload(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (discoverProvider.videos.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_library_outlined,
                  size: 48, color: Colors.white54),
              SizedBox(height: 12),
              Text('Aún no hay videos',
                  style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: VideoScrollableView(videos: discoverProvider.videos),
    );
  }
}
