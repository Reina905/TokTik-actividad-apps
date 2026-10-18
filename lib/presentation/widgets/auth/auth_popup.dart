import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';
import 'package:toktok/presentation/widgets/auth/auth_styles.dart';
import 'package:toktok/presentation/widgets/auth/login_form.dart';
import 'package:toktok/presentation/widgets/auth/register_form.dart';

enum AuthMode { login, register }


/// Ejecuta [onAuthenticated] si hay sesión iniciada;
/// si no, muestra el pop-up de inicio de sesión.
void requireAuth(BuildContext context, {VoidCallback? onAuthenticated}) {
  if (context.read<AuthProvider>().isLoggedIn) {
    onAuthenticated?.call();
    return;
  }
  showAuthPopup(context);
}


/// Muestra el pop-up de inicio de sesión / registro sobre la pantalla actual.
/// Mientras está abierto, el feed de fondo queda pausado y oscurecido.
/// Devuelve `true` si el usuario inició sesión o se registró.
Future<bool> showAuthPopup(
  BuildContext context, {
  AuthMode initialMode = AuthMode.login,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  final authenticated = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: AuthColors.barrier,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => _AuthPopup(initialMode: initialMode),
    transitionBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);

      return AnimatedBuilder(
        animation: curved,
        child: child,
        builder: (_, child) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3 * curved.value, sigmaY: 3 * curved.value),
          child: Opacity(
            opacity: curved.value,
            child: Transform.scale(scale: 0.94 + 0.06 * curved.value, child: child),
          ),
        ),
      );
    },
  ) ?? false;

  if (authenticated) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('¡Sesión iniciada!')));
  }
  return authenticated;
}


class _AuthPopup extends StatefulWidget {

  final AuthMode initialMode;

  const _AuthPopup({required this.initialMode});

  @override
  State<_AuthPopup> createState() => _AuthPopupState();
}

class _AuthPopupState extends State<_AuthPopup> {

  late AuthMode _mode = widget.initialMode;

  void _close() => Navigator.of(context).pop(false);
  void _onAuthenticated() => Navigator.of(context).pop(true);
  void _switchTo(AuthMode mode) => setState(() => _mode = mode);

  @override
  Widget build(BuildContext context) {
    final form = _mode == AuthMode.login
      ? LoginForm(
          key: const ValueKey(AuthMode.login),
          onClose: _close,
          onGoToRegister: () => _switchTo(AuthMode.register),
          onAuthenticated: _onAuthenticated,
        )
      : RegisterForm(
          key: const ValueKey(AuthMode.register),
          onClose: _close,
          onGoToLogin: () => _switchTo(AuthMode.login),
          onAuthenticated: _onAuthenticated,
        );

    // Scaffold propio: muestra los SnackBar por encima del fondo oscurecido
    // y sube el pop-up cuando aparece el teclado
    return Theme(
      data: AuthTheme.of(context),
      child: ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          // Tocar fuera del pop-up lo cierra
          body: GestureDetector(
            onTap: _close,
            behavior: HitTestBehavior.opaque,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        // Tocar dentro de la tarjeta no la cierra, solo oculta el teclado
                        child: GestureDetector(
                          onTap: () => FocusScope.of(context).unfocus(),
                          child: _PopupCard(
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                layoutBuilder: (current, previous) => Stack(
                                  alignment: Alignment.topCenter,
                                  children: [...previous, if (current != null) current],
                                ),
                                child: form,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _PopupCard extends StatelessWidget {

  final Widget child;

  const _PopupCard({required this.child});

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(26));

    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(color: Color(0x80000000), blurRadius: 70, offset: Offset(0, 28)),
        ],
      ),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(borderRadius: radius),
        child: child,
      ),
    );
  }
}
