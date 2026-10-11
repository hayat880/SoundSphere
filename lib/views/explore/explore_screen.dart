import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/library_controller.dart';
import '../../controllers/player_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/track.dart';
import '../../models/track_group.dart';
import '../library/track_group_screen.dart';
import '../online/online_screen.dart';
import '../widgets/art_tile.dart';

/// Discover your own music: most played, newly added, liked songs and your
/// biggest artists. Everything comes from the local library.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final player = context.read<PlayerController>();
    final theme = Theme.of(context);

    if (library.tracks.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Explore fills up as you add songs and listen.\n'
                    'Add or scan songs in the Library tab first.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.moss),
                  ),
                  const SizedBox(height: 16),
                  const _OnlineButton(),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final mostPlayed = library.mostPlayed;
    final added = library.newlyAdded;
    final liked = library.liked;
    final artists = library.popularArtists;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 16, bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Explore',
                  style: theme.textTheme.headlineLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _OnlineButton(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => player.shufflePlay(library.tracks),
                      icon: const Icon(Icons.shuffle),
                      label: const Text('Shuffle everything'),
                    ),
                  ),
                  if (liked.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => player.shufflePlay(liked),
                        icon: const Icon(Icons.favorite_border),
                        label: const Text('Liked mix'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (mostPlayed.isNotEmpty)
              _Shelf(
                title: 'Most played',
                tracks: mostPlayed,
                onPlay: (i) => player.playFromList(mostPlayed, i),
              ),
            if (added.isNotEmpty)
              _Shelf(
                title: 'Recently added',
                tracks: added,
                onPlay: (i) => player.playFromList(added, i),
              ),
            if (liked.isNotEmpty)
              _Shelf(
                title: 'Liked songs',
                tracks: liked,
                onPlay: (i) => player.playFromList(liked, i),
              ),
            if (artists.isNotEmpty) ...[
              const _Title('Your artists'),
              SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: artists.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, i) => _ArtistCard(group: artists[i]),
                ),
              ),
            ],
            if (mostPlayed.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Text(
                  'Play some songs to the end and your most played list '
                  'appears here.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.moss),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OnlineButton extends StatelessWidget {
  const _OnlineButton();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const OnlineScreen())),
          icon: const Icon(Icons.cloud_outlined),
          label: const Text('Find music online'),
        ),
      );
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      );
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.title, required this.tracks, required this.onPlay});
  final String title;
  final List<Track> tracks;
  final void Function(int index) onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Title(title),
        SizedBox(
          height: 156,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: tracks.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final t = tracks[i];
              return GestureDetector(
                onTap: () => onPlay(i),
                child: SizedBox(
                  width: 104,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ArtTile(
                          title: t.title,
                          size: 104,
                          radius: 14,
                          artworkPath: t.artworkPath),
                      const SizedBox(height: 6),
                      Text(t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(t.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.moss)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ArtistCard extends StatelessWidget {
  const _ArtistCard({required this.group});
  final TrackGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) =>
            TrackGroupScreen(kind: GroupKind.artist, name: group.name),
      )),
      child: SizedBox(
        width: 92,
        child: Column(
          children: [
            ArtTile(
                title: group.name,
                size: 84,
                radius: 42,
                artworkPath: group.artworkPath),
            const SizedBox(height: 6),
            Text(group.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text('${group.count} song${group.count == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.moss)),
          ],
        ),
      ),
    );
  }
}
