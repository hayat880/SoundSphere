import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/player_controller.dart';
import '../../core/theme/app_colors.dart';
import '../now_playing/now_playing_screen.dart';
import 'art_tile.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerController>();
    final track = player.currentTrack;
    if (track == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const NowPlayingScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: AppColors.darkCard2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ArtTile(
                title: track.title,
                size: 40,
                radius: 8,
                artworkPath: track.artworkPath),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.cream,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.sage, fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              onPressed: player.togglePlay,
              tooltip: player.isPlaying ? 'Pause' : 'Play',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                foregroundColor: AppColors.forest,
                minimumSize: const Size(44, 44),
              ),
              icon: Icon(player.isPlaying ? Icons.pause : Icons.play_arrow),
            ),
          ],
        ),
      ),
    );
  }
}
