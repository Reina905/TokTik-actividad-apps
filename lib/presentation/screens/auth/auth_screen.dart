import 'package:flutter/material.dart';
import 'package:toktok/presentation/widgets/auth/auth_styles.dart';
import 'package:toktok/presentation/widgets/auth/login_form.dart';
import 'package:toktok/presentation/widgets/auth/register_form.dart';

enum _AuthMode { login, register }

/// Pantalla completa de inicio de sesión / registro.
/// Reutiliza los LoginForm y RegisterForm del equipo dentro de una
/// tarjeta centrada sobre fondo oscuro.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _AuthMode _mode = _AuthMode.login;

  @override
  Widget build(BuildContext context) {
    final form = _mode == _AuthMode.login
        ? LoginForm(
            key: const ValueKey(_AuthMode.login),
            // No se puede cerrar: es la puerta de entrada a la app
            onClose: () {},
            onGoToRegister: () => setState(() => _mode = _AuthMode.register),
            // No hace falta hacer nada: AuthGate detecta el cambio de
            // AuthProvider.isLoggedIn y cambia a MainScreen automáticamente
            onAuthenticated: () {},
          )
        : RegisterForm(
            key: const ValueKey(_AuthMode.register),
            onClose: () {},
            onGoToLogin: () => setState(() => _mode = _AuthMode.login),
            onAuthenticated: () {},
          );

    return Theme(
      data: AuthTheme.of(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Material(
                      color: Colors.white,
                      clipBehavior: Clip.antiAlias,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(26)),
                      ),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          layoutBuilder: (current, previous) => Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              ...previous,
                              if (current != null) current,
                            ],
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
    );
  }
}
