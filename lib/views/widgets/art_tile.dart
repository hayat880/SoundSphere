import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Album art: the cover picture from the song's tags when there is one,
/// otherwise a coloured square with a music note.
class ArtTile extends StatelessWidget {
  const ArtTile({
    super.key,
    required this.title,
    this.size = 48,
    this.radius = 10,
    this.artworkPath,
  });

  final String title;
  final double size;
  final double radius;
  final String? artworkPath;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.artFor(title),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(Icons.music_note, color: Colors.white70, size: size * 0.45),
    );
    final path = artworkPath;
    if (path == null) return placeholder;
    final online = path.startsWith('http://') || path.startsWith('https://');
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: online
          ? Image.network(
              path,
              width: size,
              height: size,
              fit: BoxFit.cover,
              cacheWidth: (size * 3).round(),
              errorBuilder: (context, error, stack) => placeholder,
            )
          : Image.file(
              File(path),
              width: size,
              height: size,
              fit: BoxFit.cover,
              cacheWidth: (size * 3).round(),
              errorBuilder: (context, error, stack) => placeholder,
            ),
    );
  }
}
