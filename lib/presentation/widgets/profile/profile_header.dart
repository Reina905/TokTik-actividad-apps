import 'package:flutter/material.dart';
import 'package:toktok/config/helpers/human_formats.dart';
import 'package:toktok/domain/entities/user_profile.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile profile;

  final Widget actionButton;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = profile.photoUrl;

    return Column(
      children: [
        const SizedBox(height: 16),

        // Avatar: foto si existe, ícono si no
        CircleAvatar(
          radius: 48,
          backgroundColor: Colors.white12,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? const Icon(Icons.person, size: 56, color: Colors.white54)
              : null,
        ),
        const SizedBox(height: 12),

        Text(
          '@${profile.username}',
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          profile.name,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 18),

        // Estadísticas
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatItem(value: profile.following, label: 'Siguiendo'),
            const _StatDivider(),
            _StatItem(value: profile.followers, label: 'Seguidores'),
            const _StatDivider(),
            _StatItem(value: profile.likes, label: 'Me gusta'),
          ],
        ),
        const SizedBox(height: 18),

        actionButton,

        if (profile.bio.isNotEmpty) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              profile.bio,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ),
        ],
        const SizedBox(height: 18),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final int value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Column(
        children: [
          Text(
            HumanFormats.humanReadbleNumber(value.toDouble()),
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 16, color: Colors.white24);
  }
}
