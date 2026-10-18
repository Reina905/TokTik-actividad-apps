import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';
import 'package:toktok/presentation/screens/profile/creator_profile_screen.dart';
import 'package:toktok/presentation/widgets/auth/auth_popup.dart';
import 'package:toktok/presentation/widgets/auth/auth_styles.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Sin sesión: invita a iniciar sesión
    if (!authProvider.isLoggedIn) {
      return const _LoggedOutView();
    }

    // Con sesión: usa el CreatorProfileScreen del equipo con el uid del usuario.
    // Se pasa el nombre como fallback porque en LocalProfileDataSource los
    // usuarios de Firebase no existen; así se crea un perfil por defecto.
    return CreatorProfileScreen(
      uid: authProvider.userId!,
      showBackButton: false,
      fallbackName: authProvider.userName ?? 'Mi perfil',
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
