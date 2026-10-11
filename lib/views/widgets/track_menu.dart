import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/player_controller.dart';
import '../../controllers/playlist_controller.dart';
import '../../models/track.dart';
import 'playlist_dialogs.dart';

/// The "..." menu for a song: play next, add to queue, add to playlist.
/// Pass [playlistId] when opened inside a playlist to show "Remove".
Future<void> showTrackMenu(
  BuildContext context,
  Track track, {
  int? playlistId,
}) {
  final player = context.read<PlayerController>();
  final playlists = context.read<PlaylistController>();
  final messenger = ScaffoldMessenger.of(context);

  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(track.title,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(track.artist),
          ),
          ListTile(
            leading: const Icon(Icons.playlist_play),
            title: const Text('Play next'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              player.playNext(track);
              messenger.showSnackBar(
                  const SnackBar(content: Text('Will play next')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue_music),
            title: const Text('Add to queue'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              player.addToQueue(track);
              messenger.showSnackBar(
                  const SnackBar(content: Text('Added to queue')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Add to playlist'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              showAddToPlaylistSheet(context, track);
            },
          ),
          if (playlistId != null && playlistId > 0 && track.id != null)
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('Remove from this playlist'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                playlists.removeTrack(playlistId, track.id!);
              },
            ),
        ],
      ),
    ),
  );
}

Future<void> showAddToPlaylistSheet(BuildContext context, Track track) {
  final playlists = context.read<PlaylistController>();
  final messenger = ScaffoldMessenger.of(context);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Consumer<PlaylistController>(
        builder: (context, ctrl, _) => ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New playlist'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final id = await showCreatePlaylistDialog(context);
                if (id != null && track.id != null) {
                  await playlists.addTrack(id, track.id!);
                  messenger.showSnackBar(
                      const SnackBar(content: Text('Added to new playlist')));
                }
              },
            ),
            for (final p in ctrl.playlists)
              ListTile(
                leading: const Icon(Icons.queue_music),
                title: Text(p.name),
                subtitle: Text('${p.trackCount} songs'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  if (track.id == null) return;
                  await playlists.addTrack(p.id, track.id!);
                  messenger.showSnackBar(
                      SnackBar(content: Text('Added to ${p.name}')));
                },
              ),
          ],
        ),
      ),
    ),
  );
}
