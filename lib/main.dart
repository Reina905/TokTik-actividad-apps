import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/config/theme/app_theme.dart';
import 'package:toktok/firebase_options.dart';
import 'package:toktok/infrastructure/datasources/local_profile_datasource.dart';
import 'package:toktok/infrastructure/repositories/profile_repository.dart';
import 'package:toktok/infrastructure/repositories/video_repository.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';
import 'package:toktok/presentation/providers/discover_provider.dart';
import 'package:toktok/presentation/providers/upload_video_provider.dart';
import 'package:toktok/presentation/screens/auth/auth_screen.dart';
import 'package:toktok/presentation/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => DiscoverProvider()..loadNextPage(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => UploadVideoProvider(),
        ),

        // Para usar Firestore, solo cambia LocalProfileDataSource() por la otra implementación
        Provider(
          create: (_) =>
              ProfileRepository(dataSource: LocalProfileDataSource()),
        ),
        // VideoRepository para consultar videos de Firestore (feed y perfil)
        Provider(
          create: (_) => VideoRepository(),
        ),
      ],
      child: MaterialApp(
        title: 'TokTik',
        debugShowCheckedModeBanner: false,
        theme: AppTheme().getTheme(),
        home: const AuthGate(),
      ),
    );
  }
}

/// Decide qué mostrar al arrancar: si hay sesión iniciada (Firebase
/// la recuerda), va directo al feed; si no, muestra la pantalla de login.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isLoggedIn) {
      return const AuthScreen();
    }

    return const MainScreen();
  }
}
