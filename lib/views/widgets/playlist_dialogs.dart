import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/playlist_controller.dart';

/// Asks for a name and creates a playlist. Returns the new id, or null
/// if the user cancelled.
Future<int?> showCreatePlaylistDialog(BuildContext context) async {
  final playlists = context.read<PlaylistController>();
  final name = await showDialog<String>(
    context: context,
    builder: (_) => const _PlaylistNameDialog(
      title: 'New playlist',
      action: 'Create',
    ),
  );
  if (name == null || name.trim().isEmpty) return null;
  return playlists.create(name);
}

/// Asks for a new name and renames the playlist. Returns the new name, or
/// null if the user cancelled or left it empty.
Future<String?> showRenamePlaylistDialog(
  BuildContext context,
  int playlistId,
  String currentName,
) async {
  final playlists = context.read<PlaylistController>();
  final name = await showDialog<String>(
    context: context,
    builder: (_) => _PlaylistNameDialog(
      title: 'Rename playlist',
      action: 'Save',
      initial: currentName,
    ),
  );
  final clean = name?.trim() ?? '';
  if (clean.isEmpty || clean == currentName) return null;
  await playlists.rename(playlistId, clean);
  return clean;
}

class _PlaylistNameDialog extends StatefulWidget {
  const _PlaylistNameDialog({
    required this.title,
    required this.action,
    this.initial = '',
  });

  final String title;
  final String action;
  final String initial;

  @override
  State<_PlaylistNameDialog> createState() => _PlaylistNameDialogState();
}

class _PlaylistNameDialogState extends State<_PlaylistNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Playlist name'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(widget.action),
        ),
      ],
    );
  }
}
