import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/library_controller.dart';
import '../../controllers/player_controller.dart';
import '../../controllers/playlist_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/playlist.dart';
import '../../models/track.dart';
import '../widgets/art_tile.dart';
import '../widgets/mini_player.dart';
import '../widgets/playlist_dialogs.dart';
import '../widgets/track_menu.dart';
import '../widgets/track_tile.dart';

/// Shows one playlist (or Liked Songs when [playlistId] is kLikedPlaylistId).
class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({
    super.key,
    required this.playlistId,
    required this.title,
  });

  final int playlistId;
  final String title;

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  bool get _isLiked => widget.playlistId == kLikedPlaylistId;

  /// Starts as the name passed in; changes when the playlist is renamed.
  late String _title = widget.title;

  @override
  void initState() {
    super.initState();
    if (!_isLiked) {
      final playlists = context.read<PlaylistController>();
      Future.microtask(() => playlists.loadTracks(widget.playlistId));
    }
  }

  Future<void> _rename() async {
    final name = await showRenamePlaylistDialog(
        context, widget.playlistId, _title);
    if (name != null && mounted) setState(() => _title = name);
  }

  Future<void> _confirmDelete() async {
    final playlists = context.read<PlaylistController>();
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete playlist?'),
        content: Text('"${_title}" will be removed. Your songs stay in the library.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await playlists.delete(widget.playlistId);
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final playlists = context.watch<PlaylistController>();
    final player = context.read<PlayerController>();
    final theme = Theme.of(context);

    final List<Track> tracks = _isLiked
        ? library.tracks.where((t) => t.isFavorite).toList()
        : playlists
            .tracksFor(widget.playlistId)
            .map((t) => library.byId(t.id) ?? t)
            .toList();

    return Scaffold(
      bottomNavigationBar:
          const SafeArea(top: false, child: MiniPlayer()),
      appBar: AppBar(
        title: Text(_title),
        actions: [
          if (!_isLiked)
            IconButton(
              onPressed: _rename,
              tooltip: 'Rename playlist',
              icon: const Icon(Icons.edit_outlined),
            ),
          if (!_isLiked)
            IconButton(
              onPressed: _confirmDelete,
              tooltip: 'Delete playlist',
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  if (_isLiked)
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.terracotta,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.favorite,
                          size: 32, color: AppColors.forest),
                    )
                  else
                    ArtTile(title: _title, size: 72, radius: 14),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text('${tracks.length} songs',
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
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          _isLiked
                              ? 'Tap the heart on any song to add it here.'
                              : 'This playlist is empty. Use the "..." menu on a song and choose "Add to playlist".',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.moss),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: tracks.length,
                      itemBuilder: (context, i) => TrackTile(
                        track: tracks[i],
                        onTap: () => player.playFromList(tracks, i),
                        onFavorite: () => library.toggleFavorite(tracks[i]),
                        onMore: () => showTrackMenu(
                          context,
                          tracks[i],
                          playlistId: widget.playlistId,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
