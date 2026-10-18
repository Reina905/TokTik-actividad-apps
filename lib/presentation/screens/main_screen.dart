import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:toktok/presentation/providers/upload_video_provider.dart';
import 'package:toktok/presentation/screens/camera/camera_filter_screen.dart';
import 'package:toktok/presentation/screens/discover/discover_screen.dart';
import 'package:toktok/presentation/screens/feed/feed_screen.dart';
import 'package:toktok/presentation/screens/profile/profile_screen.dart';
import 'package:toktok/presentation/screens/upload/upload_screen.dart';
import 'package:toktok/presentation/widgets/shared/custom_bottom_navbar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DiscoverScreen(),
    FeedScreen(),
    SizedBox.shrink(), // índice 2 = botón +, sin pantalla
    ProfileScreen(),
  ];

  void _onTabTap(int index) {
    if (index == 2) {
      _showAddContentModal();
      return;
    }
    setState(() => _currentIndex = index);
  }

  // ── Modal principal ──────────────────────────────────────────────────────────

  void _showAddContentModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddContentSheet(
        onVideoCamera: () async {
          Navigator.pop(context);
          // Abre la cámara en vivo con filtros
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CameraFilterScreen(),
            ),
          );
        },
        onGallery: () {
          Navigator.pop(context);
          _showGalleryPicker();
        },
        onLive: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('En vivo próximamente')),
          );
        },
      ),
    );
  }

  // ── Modal de selección en galería ────────────────────────────────────────────

  void _showGalleryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _GalleryPickerSheet(
        onPickVideo: () async {
          Navigator.pop(context);
          await _pickAndNavigate(source: ImageSource.gallery, isVideo: true);
        },
        onPickPhoto: () async {
          Navigator.pop(context);
          await _pickAndNavigate(source: ImageSource.gallery, isVideo: false);
        },
      ),
    );
  }

  // ── Picker + navegación a UploadScreen ───────────────────────────────────────

  Future<void> _pickAndNavigate({
    required ImageSource source,
    required bool isVideo,
  }) async {
    final picker = ImagePicker();
    XFile? pickedFile;

    if (isVideo) {
      pickedFile = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 3),
      );
    } else {
      pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );
    }

    if (pickedFile == null || !mounted) return;

    context.read<UploadVideoProvider>().reset();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadScreen(
          file: File(pickedFile!.path),
          isVideo: isVideo,
        ),
      ),
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

// ─── Modal principal: Video | Galería | En vivo ───────────────────────────────

class _AddContentSheet extends StatelessWidget {
  final VoidCallback onVideoCamera;
  final VoidCallback onGallery;
  final VoidCallback onLive;

  const _AddContentSheet({
    required this.onVideoCamera,
    required this.onGallery,
    required this.onLive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                onTap: onVideoCamera,
              ),
              _OptionTile(
                icon: Icons.photo_library_outlined,
                label: 'Galería',
                onTap: onGallery,
              ),
              _OptionTile(
                icon: Icons.live_tv_outlined,
                label: 'En vivo',
                onTap: onLive,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Modal galería: elige Video o Foto ───────────────────────────────────────

class _GalleryPickerSheet extends StatelessWidget {
  final VoidCallback onPickVideo;
  final VoidCallback onPickPhoto;

  const _GalleryPickerSheet({
    required this.onPickVideo,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            '¿Qué quieres subir?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona el tipo de contenido de tu galería',
            style: TextStyle(fontSize: 13, color: Colors.white54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onPickVideo,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          color: Color(0xFFEE1D52),
                          size: 40,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Video',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Máx. 3 minutos',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: onPickPhoto,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.image_outlined,
                          color: Color(0xFF69C9D0),
                          size: 40,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Foto',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'JPG, PNG',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Tile genérico de opción ──────────────────────────────────────────────────

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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
