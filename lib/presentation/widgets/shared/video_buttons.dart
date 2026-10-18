import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/config/helpers/human_formats.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/infrastructure/repositories/video_repository.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';
import 'package:toktok/presentation/widgets/auth/auth_popup.dart';

class VideoButtons extends StatelessWidget {
  final VideoPost video;

  // null = video sin autor, no se muestra el avatar
  final VoidCallback? onProfileTap;

  const VideoButtons({
    super.key,
    required this.video,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Avatar + nombre del creador ──────────────────────────────────
        if (onProfileTap != null) ...[
          _CreatorAvatar(
            userName: video.userName,
            onTap: onProfileTap!,
          ),
          const SizedBox(height: 20),
        ],

        // ── Me gusta ─────────────────────────────────────────────────────
        _LikeButton(video: video),
        const SizedBox(height: 20),

        // ── Comentarios ───────────────────────────────────────────────────
        _CustomIconButton(
          value: 0,
          iconData: Icons.chat_bubble_rounded,
          onPressed: () => requireAuth(context),
        ),
        const SizedBox(height: 20),

        // ── Vistas ────────────────────────────────────────────────────────
        _CustomIconButton(
          value: video.views,
          iconData: Icons.remove_red_eye_outlined,
        ),
        const SizedBox(height: 20),

        SpinPerfect(
          infinite: true,
          duration: const Duration(seconds: 5),
          child: const _CustomIconButton(
            value: 0,
            iconData: Icons.play_circle_outline,
          ),
        ),
      ],
    );
  }
}

// ─── Me gusta (Firestore) ────────────────────────────────────────────────────

class _LikeButton extends StatefulWidget {
  final VideoPost video;

  const _LikeButton({required this.video});

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton> {
  late int _likes = widget.video.likes;
  bool _liked = false;
  bool _isToggling = false;

  String? _loadedForUid;
  bool _loadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.watch<AuthProvider>().userId;
    if (!_loadedOnce || uid != _loadedForUid) {
      _loadedOnce = true;
      _loadedForUid = uid;
      _loadStatus();
    }
  }

  @override
  void didUpdateWidget(covariant _LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.id != widget.video.id) {
      _likes = widget.video.likes;
      _liked = false;
      _loadStatus();
    }
  }

  Future<void> _loadStatus() async {
    final videoId = widget.video.id;
    if (videoId == null) return;

    try {
      final status = await context
          .read<VideoRepository>()
          .getLikeStatus(videoId: videoId, uid: _loadedForUid);

      if (!mounted || videoId != widget.video.id || _isToggling) return;
      setState(() {
        _liked = status.liked;
        _likes = status.likes;
      });
    } catch (e) {
      debugPrint('Error cargando likes: $e');
    }
  }

  Future<void> _toggleLike() async {
    final videoId = widget.video.id;
    final uid = context.read<AuthProvider>().userId;
    if (_isToggling || videoId == null || uid == null) return;

    final repository = context.read<VideoRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final wasLiked = _liked;

    setState(() {
      _isToggling = true;
      _liked = !wasLiked;
      _likes += wasLiked ? -1 : 1;
    });

    try {
      final liked = await repository.toggleLike(videoId: videoId, uid: uid);
      if (!mounted) return;
      if (liked != _liked) {
        setState(() {
          _liked = liked;
          _likes += liked ? 1 : -1;
        });
      }
    } catch (e) {
      debugPrint('Error guardando like: $e');
      if (!mounted) return;
      setState(() {
        _liked = wasLiked;
        _likes += wasLiked ? 1 : -1;
      });
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('No se pudo guardar el me gusta')),
        );
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CustomIconButton(
      value: _likes,
      iconColor: _liked ? Colors.red : Colors.white,
      iconData: Icons.favorite,
      onPressed: () => requireAuth(context, onAuthenticated: _toggleLike),
    );
  }
}

// ─── Avatar del creador con inicial / ícono genérico ─────────────────────────

class _CreatorAvatar extends StatelessWidget {
  final String? userName;
  final VoidCallback onTap;

  const _CreatorAvatar({required this.userName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Extraer la inicial del nombre para mostrarla en el avatar
    final hasName = userName != null && userName!.trim().isNotEmpty;
    final initial =
        hasName ? userName!.trim()[0].toUpperCase() : null;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.black87,
              child: initial != null
                  ? Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white70),
            ),
          ),
          // Nombre del creador debajo del avatar
          if (hasName) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                userName!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(blurRadius: 4, color: Colors.black54),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Botón de ícono con contador ──────────────────────────────────────────────

class _CustomIconButton extends StatelessWidget {
  final int value;
  final IconData iconData;
  final Color? color;
  final VoidCallback? onPressed;

  const _CustomIconButton({
    required this.value,
    required this.iconData,
    this.onPressed,
    iconColor,
  }) : color = iconColor ?? Colors.white;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed ?? () {},
          icon: Icon(iconData, color: color, size: 30),
        ),
        if (value > 0)
          Text(HumanFormats.humanReadbleNumber(value.toDouble())),
      ],
    );
  }
}
