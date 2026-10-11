import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/library_controller.dart';
import '../../controllers/player_controller.dart';
import '../../controllers/playlist_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/playlist.dart';
import '../../models/track_group.dart';
import '../playlist/playlist_screen.dart';
import '../scan/scan_screen.dart';
import 'track_group_screen.dart';
import '../widgets/art_tile.dart';
import '../widgets/playlist_dialogs.dart';
import '../widgets/track_menu.dart';
import '../widgets/track_tile.dart';

/// Opens the file picker and reports how many songs were added.
Future<void> importSongs(BuildContext context) async {
  final library = context.read<LibraryController>();
  final messenger = ScaffoldMessenger.of(context);
  final added = await library.addSongs();
  messenger.showSnackBar(SnackBar(
    content: Text(added > 0
        ? 'Added $added song${added == 1 ? '' : 's'}'
        : 'No new songs added'),
  ));
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _tab = 0; // 0 = playlists, 1 = songs, 2 = albums, 3 = artists

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Your Library',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    onPressed: () => showCreatePlaylistDialog(context),
                    tooltip: 'Create playlist',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.chip,
                      minimumSize: const Size(44, 44),
                    ),
                    icon: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                children: [
                  for (final entry in const ['Playlists', 'Songs', 'Albums', 'Artists']
                      .asMap()
                      .entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: _tab == entry.key,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _tab = entry.key),
                        selectedColor: AppColors.terracotta,
                        backgroundColor: AppColors.chip,
                        side: BorderSide.none,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _tab == entry.key
                              ? AppColors.forest
                              : AppColors.moss,
                        ),
                      ),
                    ),
                ],
              ),
              ),
            ),
            Expanded(
              child: switch (_tab) {
                0 => const _PlaylistsTab(),
                1 => const _SongsTab(),
                2 => const _GroupsTab(kind: GroupKind.album),
                _ => const _GroupsTab(kind: GroupKind.artist),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final playlists = context.watch<PlaylistController>().playlists;
    final likedCount = library.tracks.where((t) => t.isFavorite).length;

    return ListView(
      children: [
        _LibraryRow(
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.terracotta,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.favorite, color: AppColors.forest),
          ),
          title: 'Liked Songs',
          subtitle: 'Playlist • $likedCount songs',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const PlaylistScreen(
                playlistId: kLikedPlaylistId, title: 'Liked Songs'),
          )),
        ),
        for (final p in playlists)
          _LibraryRow(
            leading: ArtTile(title: p.name, size: 56),
            title: p.name,
            subtitle: 'Playlist • ${p.trackCount} songs',
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => PlaylistScreen(playlistId: p.id, title: p.name),
            )),
          ),
        if (playlists.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Tap + at the top to create your first playlist.',
              style: TextStyle(color: AppColors.moss),
            ),
          ),
      ],
    );
  }
}

class _SongsTab extends StatelessWidget {
  const _SongsTab();

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final player = context.read<PlayerController>();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Text('${library.tracks.length} songs',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ScanScreen()),
                ),
                tooltip: 'Scan phone for music',
                icon: const Icon(Icons.manage_search),
              ),
              FilledButton.icon(
                onPressed: () => importSongs(context),
                icon: const Icon(Icons.add),
                label: const Text('Add songs'),
              ),
            ],
          ),
        ),
        Expanded(
          child: library.tracks.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Your library is empty. Tap "Add songs" to choose audio files from your phone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.moss),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: library.tracks.length,
                  itemBuilder: (context, i) => TrackTile(
                    track: library.tracks[i],
                    onTap: () => player.playFromList(library.tracks, i),
                    onFavorite: () => library.toggleFavorite(library.tracks[i]),
                    onMore: () => showTrackMenu(context, library.tracks[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Albums or Artists: every song grouped by that field.
class _GroupsTab extends StatelessWidget {
  const _GroupsTab({required this.kind});
  final GroupKind kind;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final groups =
        kind == GroupKind.album ? library.albums : library.artists;
    final label = kind == GroupKind.album ? 'Album' : 'Artist';

    if (groups.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Nothing here yet. Add or scan songs in the Songs tab.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.moss),
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final g = groups[i];
        return _LibraryRow(
          leading: ArtTile(
              title: g.name, size: 56, artworkPath: g.artworkPath),
          title: g.name,
          subtitle: '$label • ${g.count} song${g.count == 1 ? '' : 's'}',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => TrackGroupScreen(kind: kind, name: g.name),
          )),
        );
      },
    );
  }
}

class _LibraryRow extends StatelessWidget {
  const _LibraryRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.moss)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
