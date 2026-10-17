import 'package:flutter/material.dart';
import 'package:toktok/presentation/screens/discover/discover_screen.dart';
import 'package:toktok/presentation/screens/feed/feed_screen.dart';
import 'package:toktok/presentation/screens/profile/profile_screen.dart';
import 'package:toktok/presentation/widgets/shared/custom_bottom_navbar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Las pantallas se mantienen vivas con IndexedStack (no se recrean al cambiar tab)
  final List<Widget> _screens = const [
    DiscoverScreen(),
    FeedScreen(),
    // Índice 2 es el botón "+", no tiene pantalla asociada
    SizedBox.shrink(),
    ProfileScreen(),
  ];

  void _onTabTap(int index) {
    // El botón "+" (índice 2) abre un modal en lugar de navegar
    if (index == 2) {
      _showAddContentModal();
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _showAddContentModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddContentSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
      ),
    );
  }
}

// ─── Modal de agregar contenido ───────────────────────────────────────────────

class _AddContentSheet extends StatelessWidget {
  const _AddContentSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador superior
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Crear contenido',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _OptionTile(
                icon: Icons.videocam_outlined,
                label: 'Video',
                onTap: () => Navigator.pop(context),
              ),
              _OptionTile(
                icon: Icons.photo_library_outlined,
                label: 'Galería',
                onTap: () => Navigator.pop(context),
              ),
              _OptionTile(
                icon: Icons.live_tv_outlined,
                label: 'En vivo',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
