import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';
import 'package:toktok/presentation/screens/profile/creator_profile_screen.dart';
import 'package:toktok/presentation/widgets/auth/auth_popup.dart';
import 'package:toktok/presentation/widgets/auth/auth_styles.dart';

/// Perfil propio del usuario logueado.
/// Expone [refresh()] para que [MainScreen] pueda recargar los videos
/// automáticamente cada vez que el usuario toca el tab de perfil.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  /// Llama a este método desde fuera para recargar el perfil.
  /// Ejemplo: globalKey.currentState?.refresh()
  void refresh() {
    // La implementación real está en el State — Flutter enrutará la llamada.
  }

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  // Clave para acceder al estado de CreatorProfileScreen y llamar reload()
  final _profileKey = GlobalKey<CreatorProfileScreenState>();

  /// Recarga los videos del perfil desde Firestore.
  void refresh() {
    _profileKey.currentState?.reloadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isLoggedIn) {
      return const _LoggedOutView();
    }

    return CreatorProfileScreen(
      key: _profileKey,
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
              child: Icon(
                Icons.person_outline,
                size: 56,
                color: Colors.white54,
              ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
