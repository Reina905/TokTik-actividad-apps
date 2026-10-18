import 'package:flutter/material.dart';
import 'package:toktok/presentation/widgets/video/video_background.dart';
import 'package:video_player/video_player.dart';

class FullScreenPlayer extends StatefulWidget {
  final String videoUrl;
  final String caption;

  const FullScreenPlayer(
      {super.key, required this.videoUrl, required this.caption});

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
  late VideoPlayerController controller;
  late Future<void> initialization;

  // true si el video se pausó porque se abrió algo encima (pop-up, modal)
  bool pausedByOverlay = false;

  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..setVolume(0)
      ..setLooping(true)
      ..play();

    // Se guarda para no reinicializar el video en cada rebuild
    initialization = controller.initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ModalRoute.of hace que este método se llame cuando otra ruta
    // (como el pop-up de inicio de sesión) se abre o se cierra encima
    final isVisible = ModalRoute.of(context)?.isCurrent ?? true;

    if (!isVisible && controller.value.isPlaying) {
      controller.pause();
      pausedByOverlay = true;
    } else if (isVisible && pausedByOverlay) {
      controller.play();
      pausedByOverlay = false;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        return GestureDetector(
          onTap: () {
            if (controller.value.isPlaying) {
              controller.pause();
              return;
            }
            controller.play();
          },
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: Stack(
              children: [
                VideoPlayer(controller),

                // Gradiente
                VideoBackground(
                  stops: const [0.8, 1.0],
                ),

                // Texto
                Positioned(
                    bottom: 50,
                    left: 20,
                    child: _VideoCaption(caption: widget.caption)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VideoCaption extends StatelessWidget {
  final String caption;

  const _VideoCaption({required this.caption});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final titleStyle = Theme.of(context).textTheme.titleLarge;

    return SizedBox(
      width: size.width * 0.6,
      child: Text(caption, maxLines: 2, style: titleStyle),
    );
  }
}
