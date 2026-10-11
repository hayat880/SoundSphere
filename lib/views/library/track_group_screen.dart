import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/library_controller.dart';
import '../../controllers/player_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/track.dart';
import '../../models/track_group.dart';
import '../widgets/art_tile.dart';
import '../widgets/mini_player.dart';
import '../widgets/track_menu.dart';
import '../widgets/track_tile.dart';

/// The songs of one album or one artist, with Play and Shuffle.
class TrackGroupScreen extends StatelessWidget {
  const TrackGroupScreen({super.key, required this.kind, required this.name});

  final GroupKind kind;
  final String name;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final player = context.read<PlayerController>();
    final theme = Theme.of(context);

    final groups = kind == GroupKind.album ? library.albums : library.artists;
    final List<Track> tracks = [
      for (final g in groups)
        if (g.name == name) ...g.tracks,
    ];

    return Scaffold(
      bottomNavigationBar:
          const SafeArea(top: false, child: MiniPlayer()),
      appBar: AppBar(title: Text(name)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  ArtTile(
                      title: name,
                      size: 72,
                      radius: 14,
                      artworkPath: tracks
                          .map((t) => t.artworkPath)
                          .firstWhere((a) => a != null, orElse: () => null)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text(
                            '${kind == GroupKind.album ? 'Album' : 'Artist'} • ${tracks.length} songs',
                            style: const TextStyle(color: AppColors.moss)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: tracks.isEmpty
                          ? null
                          : () => player.playFromList(tracks, 0),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          tracks.isEmpty ? null : () => player.shufflePlay(tracks),
                      icon: const Icon(Icons.shuffle),
                      label: const Text('Shuffle'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tracks.isEmpty
                  ? const Center(
                      child: Text('No songs here.',
                          style: TextStyle(color: AppColors.moss)),
                    )
                  : ListView.builder(
                      itemCount: tracks.length,
                      itemBuilder: (context, i) => TrackTile(
                        track: tracks[i],
                        onTap: () => player.playFromList(tracks, i),
                        onFavorite: () => library.toggleFavorite(tracks[i]),
                        onMore: () => showTrackMenu(context, tracks[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
