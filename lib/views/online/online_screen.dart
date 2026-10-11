import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/online_controller.dart';
import '../../controllers/player_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../models/online_track.dart';
import '../widgets/art_tile.dart';
import '../widgets/mini_player.dart';
import '../widgets/track_menu.dart';

const List<String> _quickWords = [
  'Bollywood',
  'Pakistani',
  'Punjabi',
  'Urdu',
  'Sufi',
  'Qawwali',
  'Lofi',
];

/// Search free songs online (Audius), play them, or add them to a playlist.
class OnlineScreen extends StatefulWidget {
  const OnlineScreen({super.key});

  @override
  State<OnlineScreen> createState() => _OnlineScreenState();
}

class _OnlineScreenState extends State<OnlineScreen> {
  final _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<OnlineController>().loadTrendingOnce();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _play(OnlineTrack song) async {
    final online = context.read<OnlineController>();
    final player = context.read<PlayerController>();
    final saved = await online.addToLibrary(song);
    if (saved != null) player.playFromList([saved], 0);
  }

  Future<void> _addToPlaylist(OnlineTrack song) async {
    final online = context.read<OnlineController>();
    final saved = await online.addToLibrary(song);
    if (saved == null || !mounted) return;
    await showAddToPlaylistSheet(context, saved);
  }

  Future<void> _download(OnlineTrack song) async {
    final online = context.read<OnlineController>();
    final messenger = ScaffoldMessenger.of(context);
    final message = await online.download(song);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _quickSearch(String word) {
    _text.text = word;
    context.read<OnlineController>().search(word);
  }

  @override
  Widget build(BuildContext context) {
    final online = context.watch<OnlineController>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Find music online')),
      bottomNavigationBar: const SafeArea(top: false, child: MiniPlayer()),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: TextField(
                controller: _text,
                textInputAction: TextInputAction.search,
                onSubmitted: online.search,
                decoration: InputDecoration(
                  hintText: 'Search songs and artists online',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Search',
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => online.search(_text.text),
                  ),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _quickWords.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) => ActionChip(
                  label: Text(_quickWords[i]),
                  onPressed: () => _quickSearch(_quickWords[i]),
                ),
              ),
            ),
            _chipRow(
              [
                for (final f in OnlineFeed.values)
                  ChoiceChip(
                    label: Text(f.label),
                    selected: online.query.isEmpty && online.feed == f,
                    onSelected: (_) {
                      _text.clear();
                      online.setFeed(f);
                    },
                  ),
              ],
            ),
            _chipRow(
              [
                ChoiceChip(
                  label: const Text('All genres'),
                  selected: online.genre == null,
                  onSelected: (_) => online.setGenre(null),
                ),
                for (final g in onlineGenres)
                  ChoiceChip(
                    label: Text(g),
                    selected: online.genre == g,
                    onSelected: (_) => online.setGenre(g),
                  ),
              ],
            ),
            SwitchListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: const Text('Only songs I can download'),
              value: online.onlyDownloadable,
              onChanged: online.setOnlyDownloadable,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
              child: Text(
                online.query.isEmpty ? online.feed.label : 'Results',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(child: _body(context, online)),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                  'Free music from Audius. Downloads are only offered when the '
                  'artist allows them. Downloaded songs play offline.',
                  style: TextStyle(color: AppColors.moss, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipRow(List<Widget> chips) => SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          itemCount: chips.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, i) => chips[i],
        ),
      );

  Widget _body(BuildContext context, OnlineController online) {
    if (online.loading) return const Center(child: CircularProgressIndicator());
    if (online.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(online.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.moss)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => online.search(_text.text),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    if (online.results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
              'No songs found. Try another genre, or turn off '
              '"Only songs I can download".',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.moss)),
        ),
      );
    }
    return ListView.builder(
      itemCount: online.results.length,
      itemBuilder: (context, i) {
        final song = online.results[i];
        return ListTile(
          leading: ArtTile(title: song.title, artworkPath: song.artworkUrl),
          title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${song.artist}${song.durationSeconds > 0 ? ' • ${mmss(song.durationSeconds)}' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _play(song),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DownloadButton(
                song: song,
                busy: online.downloading.contains(song.id),
                done: online.downloaded.contains(song.id),
                onPressed: () => _download(song),
              ),
              IconButton(
                tooltip: 'Add to playlist',
                icon: const Icon(Icons.playlist_add),
                onPressed: () => _addToPlaylist(song),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({
    required this.song,
    required this.busy,
    required this.done,
    required this.onPressed,
  });

  final OnlineTrack song;
  final bool busy;
  final bool done;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (done) {
      return const IconButton(
        tooltip: 'Downloaded',
        onPressed: null,
        icon: Icon(Icons.download_done, color: AppColors.olive),
      );
    }
    return IconButton(
      tooltip: song.downloadable
          ? 'Download for offline'
          : 'The artist has not allowed downloads',
      onPressed: onPressed,
      icon: Icon(
        Icons.download_outlined,
        color: song.downloadable ? null : AppColors.border,
      ),
    );
  }
}
