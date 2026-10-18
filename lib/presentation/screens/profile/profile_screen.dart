import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';
import 'package:toktok/presentation/widgets/auth/auth_popup.dart';
import 'package:toktok/presentation/widgets/auth/auth_styles.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: authProvider.isLoggedIn
        ? _LoggedInView(authProvider: authProvider)
        : const _LoggedOutView(),
    );
  }
}


// ─── Sin sesión: invita a iniciar sesión ──────────────────────────────────────

class _LoggedOutView extends StatelessWidget {
  const _LoggedOutView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: Colors.white12,
              child: Icon(Icons.person_outline, size: 56, color: Colors.white54),
            ),
            const SizedBox(height: 20),
            const Text(
              'Inicia sesión con una cuenta registrada',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 240,
              height: 48,
              child: FilledButton(
                onPressed: () => showAuthPopup(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AuthColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: const Text('Iniciar sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── Con sesión: perfil pendiente de implementar ──────────────────────────────

class _LoggedInView extends StatelessWidget {

  final AuthProvider authProvider;

  const _LoggedInView({required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, size: 48, color: Colors.white54),
          ),
          const SizedBox(height: 12),
          Text(
            authProvider.userName ?? 'Perfil',
            style: const TextStyle(fontSize: 22, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            authProvider.userEmail ?? '',
            style: const TextStyle(fontSize: 14, color: Colors.white54),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: authProvider.logout,
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
