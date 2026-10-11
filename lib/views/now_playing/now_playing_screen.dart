import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/focus_controller.dart';
import '../../controllers/library_controller.dart';
import '../../controllers/player_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../services/player_service.dart';
import '../queue/queue_screen.dart';
import '../widgets/art_tile.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      Theme(data: AppTheme.dark, child: const _NowPlayingBody());
}

class _NowPlayingBody extends StatelessWidget {
  const _NowPlayingBody();

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerController>();
    final library = context.watch<LibraryController>();
    final focus = context.watch<FocusController>();
    final track = player.currentTrack;
    final theme = Theme.of(context);

    if (track == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Nothing is playing')),
      );
    }
    final isFavorite = library.byId(track.id)?.isFavorite ?? track.isFavorite;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          tooltip: 'Close player',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('NOW PLAYING',
            style: theme.textTheme.labelLarge
                ?.copyWith(letterSpacing: 1.2, color: AppColors.sage)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music),
            tooltip: 'Queue',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const QueueScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          children: [
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, box) => ArtTile(
                  title: track.title,
                  size: box.maxWidth,
                  radius: 24,
                  artworkPath: track.artworkPath,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(track.artist,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(color: AppColors.sage)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => library.toggleFavorite(track),
                  tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? AppColors.terracotta : AppColors.sage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<Duration?>(
              stream: player.durationStream,
              builder: (context, durationSnap) {
                final total = durationSnap.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder: (context, positionSnap) {
                    final position = positionSnap.data ?? Duration.zero;
                    final maxMs = total.inMilliseconds > 0
                        ? total.inMilliseconds.toDouble()
                        : 1.0;
                    final valueMs = position.inMilliseconds
                        .clamp(0, maxMs.toInt())
                        .toDouble();
                    return Column(
                      children: [
                        Slider(
                          value: valueMs,
                          max: maxMs,
                          onChanged: (v) =>
                              player.seek(Duration(milliseconds: v.round())),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(mmss(position.inSeconds),
                                  style: const TextStyle(color: AppColors.sage)),
                              Text(mmss(total.inSeconds),
                                  style: const TextStyle(color: AppColors.sage)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: player.toggleShuffle,
                  tooltip: player.shuffleEnabled ? 'Shuffle on' : 'Shuffle off',
                  icon: Icon(Icons.shuffle,
                      color: player.shuffleEnabled
                          ? AppColors.terracotta
                          : AppColors.sage),
                ),
                IconButton(
                  onPressed: player.previous,
                  tooltip: 'Previous',
                  iconSize: 36,
                  icon: const Icon(Icons.skip_previous),
                ),
                IconButton(
                  onPressed: player.togglePlay,
                  tooltip: player.isPlaying ? 'Pause' : 'Play',
                  iconSize: 40,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: AppColors.forest,
                    minimumSize: const Size(72, 72),
                  ),
                  icon: Icon(player.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                IconButton(
                  onPressed: player.next,
                  tooltip: 'Next',
                  iconSize: 36,
                  icon: const Icon(Icons.skip_next),
                ),
                IconButton(
                  onPressed: player.cycleRepeat,
                  tooltip: 'Repeat',
                  icon: Icon(
                    player.repeatMode == QueueRepeat.one
                        ? Icons.repeat_one
                        : Icons.repeat,
                    color: player.repeatMode == QueueRepeat.off
                        ? AppColors.sage
                        : AppColors.terracotta,
                  ),
                ),
              ],
            ),
            if (focus.status != FocusStatus.idle) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        focus.status == FocusStatus.running
                            ? 'Focus session running'
                            : 'Focus session paused',
                        style: const TextStyle(
                            color: AppColors.terracotta,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(mmss(focus.remainingSeconds),
                        style: const TextStyle(
                            color: AppColors.terracotta,
                            fontWeight: FontWeight.w700,
                            fontSize: 20)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
