import 'package:flutter/material.dart';

import 'mlkit_basico_screen.dart';
import 'filtros_faciales_screen.dart';
import 'filtros_en_vivo_screen.dart';

void main() {
  runApp(const ClaseApp());
}

class ClaseApp extends StatelessWidget {
  const ClaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clase 24 · ML Kit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1F3864),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clase 24 — ML Kit'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Dos demostraciones, la misma idea de fondo: convertir una '
            'imagen en un InputImage y pasarla a un procesador de ML Kit '
            'que corre on-device.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          _MenuCard(
            icon: Icons.text_snippet_outlined,
            title: 'ML Kit básico',
            subtitle:
                'Reconocimiento de texto, etiquetado de imagen y conteo de '
                'rostros — los tres reconocedores del guion de la Clase 24.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MLKitBasicoScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _MenuCard(
            icon: Icons.face_retouching_natural,
            title: 'Filtros faciales (lentes y bigote)',
            subtitle:
                'Usa los landmarks del FaceDetector (ojos, nariz, boca) '
                'para colocar lentes y bigote sobre cada rostro detectado — '
                'un adelanto de las opciones que se profundizan en la '
                'Clase 29.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FiltrosFacialesScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _MenuCard(
            icon: Icons.videocam_outlined,
            title: 'Filtros en vivo (cámara)',
            subtitle:
                'Los mismos lentes y bigote, pero sobre el video de la '
                'cámara en tiempo real: cada frame se convierte en un '
                'InputImage y se procesa mientras la cámara sigue grabando.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FiltrosEnVivoScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 32, color: const Color(0xFF1F3864)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
