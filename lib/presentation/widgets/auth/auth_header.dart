import 'package:flutter/material.dart';
import 'package:toktok/presentation/widgets/auth/auth_styles.dart';

// Cabecera de color con logo y botón de cerrar
class AuthHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isRegister;
  final VoidCallback onClose;

  const AuthHeader({
    super.key,
    required this.title,
    required this.onClose,
    this.subtitle,
    this.isRegister = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: AuthColors.accent,
      padding: const EdgeInsets.fromLTRB(22, 14, 14, 20),
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AuthLogo(size: isRegister ? 24 : 28),
              const SizedBox(width: 8),
              isRegister
                  ? Text(
                      'REGISTRO',
                      style: textTheme.labelMedium?.copyWith(
                        color: AuthColors.headerSubtitle,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                      ),
                    )
                  : Text(
                      'TokTik',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              const Spacer(),
              _CloseButton(onPressed: onClose),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              subtitle!,
              style: textTheme.bodyMedium
                  ?.copyWith(color: AuthColors.headerSubtitle),
            ),
          ],
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CloseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: 'Cerrar',
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.16),
        fixedSize: const Size(44, 44),
      ),
      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
    );
  }
}

class _AuthLogo extends StatelessWidget {
  final double size;

  const _AuthLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 26 / 24,
      height: size,
      child: const CustomPaint(painter: _LogoPainter()),
    );
  }
}

// Logo: dos tarjetas superpuestas con un botón de play (viewBox 26x24)
class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 26, size.height / 24);

    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fill = Paint()..color = Colors.white;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(2, 5, 16, 17), const Radius.circular(5)),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(9, 2, 15, 16), const Radius.circular(5)),
      fill,
    );

    final play = Path()
      ..moveTo(15, 7.2)
      ..lineTo(19.6, 10)
      ..lineTo(15, 12.8)
      ..close();
    canvas.drawPath(play, Paint()..color = AuthColors.accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
