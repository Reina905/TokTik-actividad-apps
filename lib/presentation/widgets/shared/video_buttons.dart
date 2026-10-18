import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:toktok/config/helpers/human_formats.dart';
import 'package:toktok/domain/entities/video_post.dart';
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
        _CustomIconButton(
          value: video.likes,
          iconColor: Colors.red,
          iconData: Icons.favorite,
          onPressed: () => requireAuth(context),
        ),
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
