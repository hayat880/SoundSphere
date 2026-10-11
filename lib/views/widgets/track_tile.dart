import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/player_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/track.dart';
import 'art_tile.dart';

class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.track,
    required this.onTap,
    required this.onFavorite,
    this.onMore,
  });

  final Track track;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playingId =
        context.select<PlayerController, int?>((p) => p.currentTrack?.id);
    final isCurrent = track.id != null && track.id == playingId;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 4, top: 4, bottom: 4),
        child: Row(
          children: [
            ArtTile(title: track.title, artworkPath: track.artworkPath),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isCurrent ? AppColors.terracotta : null)),
                  Row(
                    children: [
                      if (track.isOnline)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.cloud_outlined,
                              size: 14, color: AppColors.moss),
                        ),
                      Expanded(
                        child: Text(track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppColors.moss)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isCurrent)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.graphic_eq,
                    color: AppColors.terracotta, size: 22),
              ),
            IconButton(
              onPressed: onFavorite,
              tooltip: track.isFavorite ? 'Remove favorite' : 'Add favorite',
              icon: Icon(
                track.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: track.isFavorite ? AppColors.terracotta : AppColors.moss,
              ),
            ),
            if (onMore != null)
              IconButton(
                onPressed: onMore,
                tooltip: 'More options',
                icon: const Icon(Icons.more_vert, color: AppColors.moss),
              ),
          ],
        ),
      ),
    );
  }
}
