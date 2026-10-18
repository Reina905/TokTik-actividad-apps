import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:toktok/config/helpers/human_formats.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/presentation/widgets/auth/auth_popup.dart';


class VideoButtons extends StatelessWidget {

  final VideoPost video;

  const VideoButtons({
    super.key, 
    required this.video
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Me gusta y comentarios requieren sesión iniciada
        _CustomIconButton(
          value: video.likes,
          iconColor: Colors.red,
          iconData: Icons.favorite,
          onPressed: () => requireAuth(context),
        ),
        const SizedBox( height: 20 ),
        _CustomIconButton(
          value: 0,
          iconData: Icons.chat_bubble_rounded,
          onPressed: () => requireAuth(context),
        ),
        const SizedBox( height: 20 ),
        _CustomIconButton( value: video.views, iconData: Icons.remove_red_eye_outlined ),

        const SizedBox( height: 20 ),
        SpinPerfect(
          infinite: true,
          duration: const Duration( seconds: 5),
          child: const _CustomIconButton( value: 0, iconData: Icons.play_circle_outline )
        ),
      ],
    );
  }
}


class _CustomIconButton extends StatelessWidget {

  final int value;
  final IconData iconData;
  final Color? color;
  final VoidCallback? onPressed;

  const _CustomIconButton({
    required this.value, 
    required this.iconData, 
    this.onPressed,
    iconColor
  }): color = iconColor ?? Colors.white;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed ?? () {}, 
          icon: Icon( iconData, color: color, size: 30, )),

        if ( value > 0 )
        Text( HumanFormats.humanReadbleNumber(value.toDouble()) ),
      ],
    );
  }
}
