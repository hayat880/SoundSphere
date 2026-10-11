import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/focus_controller.dart';
import '../../controllers/library_controller.dart';
import '../../controllers/playlist_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../models/playlist.dart';
import '../../models/track.dart';
import '../ambient/ambient_screen.dart';
import '../stats/stats_screen.dart';

class _Preset {
  const _Preset(this.label, this.seconds);
  final String label;
  final int seconds;
}

const List<_Preset> _breakPresets = [
  _Preset('Demo 5s', 5),
  _Preset('5 min', 300),
  _Preset('10 min', 600),
  _Preset('15 min', 900),
];

const List<_Preset> _presets = [
  _Preset('Demo 10s', 10),
  _Preset('15 min', 900),
  _Preset('25 min', 1500),
  _Preset('45 min', 2700),
];

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusController>();
    final theme = Theme.of(context);
    final idle = focus.status == FocusStatus.idle;
    final subtitle = focus.onBreak
        ? 'Break time. Rest and recharge'
        : switch (focus.status) {
            FocusStatus.idle => 'Ready when you are',
            FocusStatus.running => 'Session in progress',
            FocusStatus.paused => 'Paused',
          };

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Focus Mode',
                          style: theme.textTheme.headlineLarge
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(subtitle,
                          style: const TextStyle(color: AppColors.sage)),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const StatsScreen()),
                  ),
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('Stats'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.terracotta),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: focus.displayProgress,
                      strokeWidth: 10,
                      backgroundColor: AppColors.darkCard2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.terracotta),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(mmss(focus.displaySeconds),
                              style: theme.textTheme.displayMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                              focus.onBreak
                                  ? 'break of ${durationLabel(focus.breakSeconds)}'
                                  : 'of ${durationLabel(focus.selectedSeconds)}',
                              style: const TextStyle(color: AppColors.sage)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                for (final p in _presets)
                  ChoiceChip(
                    label: Text(p.label),
                    selected: focus.selectedSeconds == p.seconds,
                    showCheckmark: false,
                    onSelected: idle ? (_) => focus.selectSeconds(p.seconds) : null,
                    selectedColor: AppColors.terracotta,
                    backgroundColor: AppColors.darkCard2,
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: focus.selectedSeconds == p.seconds
                          ? AppColors.forest
                          : AppColors.sage,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('BREAK LENGTH',
                  style: TextStyle(
                      color: AppColors.sage,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      fontSize: 12)),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                for (final p in _breakPresets)
                  ChoiceChip(
                    label: Text(p.label),
                    selected: focus.breakSeconds == p.seconds,
                    showCheckmark: false,
                    onSelected: focus.onBreak
                        ? null
                        : (_) => focus.selectBreakSeconds(p.seconds),
                    selectedColor: AppColors.moss,
                    backgroundColor: AppColors.darkCard2,
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: focus.breakSeconds == p.seconds
                          ? AppColors.forest
                          : AppColors.sage,
                    ),
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start break automatically'),
              value: focus.autoBreak,
              onChanged: focus.setAutoBreak,
            ),
            const SizedBox(height: 4),
            _InfoRow(
              icon: focus.selectedTrackId != null
                  ? Icons.music_note
                  : Icons.queue_music,
              title: focus.playlistName,
              subtitle: !idle
                  ? 'Playing now. Tap to change'
                  : focus.selectedTrackId != null
                      ? 'One song, repeats during the session'
                      : 'Tap to choose what plays',
              onTap: () => _pickPlaylist(context),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.waves,
              title: 'Ambient sounds',
              subtitle: 'Layer rain, waves and more',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AmbientScreen()),
              ),
            ),
            const SizedBox(height: 20),
            if (focus.onBreak)
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                        onPressed: focus.start,
                        child: const Text('Start next session')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                        onPressed: focus.skipBreak,
                        child: const Text('Skip break')),
                  ),
                ],
              )
            else if (idle)
              FilledButton(onPressed: focus.start, child: const Text('Start'))
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: focus.status == FocusStatus.running
                          ? focus.pause
                          : focus.resume,
                      child: Text(focus.status == FocusStatus.running
                          ? 'Pause'
                          : 'Resume'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: focus.stop,
                      child: const Text('Stop'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WHEN THE TIMER ENDS',
                      style: TextStyle(
                          color: AppColors.sage,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  SizedBox(height: 8),
                  Text('Music and ambient sounds fade out\nThe session is saved\nA short break starts automatically',
                      style: TextStyle(height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.terracotta),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.sage, fontSize: 13)),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: AppColors.sage),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _pickPlaylist(BuildContext context) async {
  final focus = context.read<FocusController>();
  final playlists = context.read<PlaylistController>().playlists;
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: const Icon(Icons.library_music),
            title: const Text('All songs'),
            onTap: () {
              focus.selectPlaylist(null, 'All songs');
              Navigator.of(sheetContext).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Liked Songs'),
            onTap: () {
              focus.selectPlaylist(kLikedPlaylistId, 'Liked Songs');
              Navigator.of(sheetContext).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text('A specific song'),
            subtitle: const Text('Plays and repeats during the session'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _pickSong(context);
            },
          ),
          for (final p in playlists)
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: Text(p.name),
              subtitle: Text('${p.trackCount} songs'),
              onTap: () {
                focus.selectPlaylist(p.id, p.name);
                Navigator.of(sheetContext).pop();
              },
            ),
        ],
      ),
    ),
  );
}

Future<void> _pickSong(BuildContext context) async {
  final focus = context.read<FocusController>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _SongPickerSheet(
      onPick: (track) {
        final id = track.id;
        if (id != null) focus.selectTrack(id, track.title);
        Navigator.of(sheetContext).pop();
      },
    ),
  );
}

/// A searchable list of every song in the library.
class _SongPickerSheet extends StatefulWidget {
  const _SongPickerSheet({required this.onPick});
  final void Function(Track track) onPick;

  @override
  State<_SongPickerSheet> createState() => _SongPickerSheetState();
}

class _SongPickerSheetState extends State<_SongPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final all = context.read<LibraryController>().tracks;
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty
        ? all
        : all
            .where((t) =>
                t.title.toLowerCase().contains(q) ||
                t.artist.toLowerCase().contains(q))
            .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search your songs',
                  ),
                ),
              ),
              Expanded(
                child: shown.isEmpty
                    ? const Center(
                        child: Text('No songs found.',
                            style: TextStyle(color: AppColors.sage)),
                      )
                    : ListView.builder(
                        itemCount: shown.length,
                        itemBuilder: (context, i) => ListTile(
                          leading: const Icon(Icons.music_note),
                          title: Text(shown[i].title,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(shown[i].artist,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => widget.onPick(shown[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
