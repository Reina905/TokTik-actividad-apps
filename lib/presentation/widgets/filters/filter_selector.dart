import 'package:flutter/material.dart';

import 'face_filter_utils.dart';

/// Barra horizontal con los 3 filtros disponibles.
/// Se muestra en la parte inferior de la pantalla de cámara y de foto.
class FilterSelector extends StatelessWidget {
  final FaceFilterType selected;
  final ValueChanged<FaceFilterType> onSelect;

  const FilterSelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: Colors.black.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _FilterChip(
            label: 'Sin filtro',
            emoji: '🚫',
            type: FaceFilterType.none,
            isSelected: selected == FaceFilterType.none,
            onTap: onSelect,
          ),
          _FilterChip(
            label: 'Reno',
            emoji: '🦌',
            type: FaceFilterType.reno,
            isSelected: selected == FaceFilterType.reno,
            onTap: onSelect,
          ),
          _FilterChip(
            label: 'Minion',
            emoji: '💛',
            type: FaceFilterType.minion,
            isSelected: selected == FaceFilterType.minion,
            onTap: onSelect,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String emoji;
  final FaceFilterType type;
  final bool isSelected;
  final ValueChanged<FaceFilterType> onTap;

  const _FilterChip({
    required this.label,
    required this.emoji,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEE1D52).withOpacity(0.85)
              : Colors.white12,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFEE1D52) : Colors.white24,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
