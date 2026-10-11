import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/player_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/track.dart';
import '../../services/player_service.dart';
import '../widgets/art_tile.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      Theme(data: AppTheme.dark, child: const _QueueBody());
}

class _QueueBody extends StatelessWidget {
  const _QueueBody();

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerController>();
    final queue = player.queue;
    final cur = player.currentIndex;
    final upcoming = (cur >= 0 && cur + 1 < queue.length)
        ? queue.sublist(cur + 1)
        : <Track>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue'),
        actions: [
          IconButton(
            onPressed: player.toggleShuffle,
            tooltip: player.shuffleEnabled ? 'Shuffle on' : 'Shuffle off',
            icon: Icon(Icons.shuffle,
                color: player.shuffleEnabled
                    ? AppColors.terracotta
                    : AppColors.sage),
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
      body: SafeArea(
        child: (queue.isEmpty || cur < 0)
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Your queue is empty. Play a song, or use "Add to queue" in the "..." menu of any song.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.sage),
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Label('Now playing'),
                  ListTile(
                    leading: ArtTile(
                        title: queue[cur].title,
                        artworkPath: queue[cur].artworkPath),
                    title: Text(queue[cur].title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.terracotta,
                            fontWeight: FontWeight.w700)),
                    subtitle: Text(queue[cur].artist),
                    trailing: Icon(
                      player.isPlaying ? Icons.equalizer : Icons.pause,
                      color: AppColors.terracotta,
                    ),
                  ),
                  _Label('Next up · ${upcoming.length}'),
                  Expanded(
                    child: upcoming.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'Nothing queued next. Use "Add to queue" or "Play next" in the "..." menu of any song.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.sage),
                              ),
                            ),
                          )
                        : ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            itemCount: upcoming.length,
                            onReorderItem: (oldIndex, newIndex) =>
                                player.moveInQueue(
                                    cur + 1 + oldIndex, cur + 1 + newIndex),
                            itemBuilder: (context, i) {
                              final t = upcoming[i];
                              return ListTile(
                                key: ValueKey('$i-${t.id}'),
                                leading: ArtTile(title: t.title, artworkPath: t.artworkPath),
                                title: Text(t.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(t.artist,
                                    style: const TextStyle(
                                        color: AppColors.sage)),
                                onTap: () => player.jumpTo(cur + 1 + i),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          player.removeFromQueue(cur + 1 + i),
                                      tooltip: 'Remove from queue',
                                      icon: const Icon(Icons.close,
                                          color: AppColors.sage),
                                    ),
                                    ReorderableDragStartListener(
                                      index: i,
                                      child: const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Icon(Icons.drag_handle,
                                            color: AppColors.sage),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.sage,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8)),
    );
  }
}
