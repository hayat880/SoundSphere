import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/account_controller.dart';
import '../../controllers/library_controller.dart';
import '../../controllers/player_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../account/account_screen.dart';
import '../library/library_screen.dart';
import '../settings/settings_screen.dart';
import '../widgets/art_tile.dart';
import '../widgets/track_menu.dart';
import '../widgets/track_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenFocus});
  final VoidCallback onOpenFocus;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final player = context.read<PlayerController>();
    final theme = Theme.of(context);
    final account = context.watch<AccountController>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                account.profile == null
                                    ? greeting()
                                    : '${greeting()}, ${account.displayName}',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.moss)),
                            Text('SoundSphere',
                                style: theme.textTheme.headlineLarge
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Settings',
                        icon: const Icon(Icons.settings_outlined, size: 28),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const SettingsScreen()),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Account',
                        icon: const Icon(Icons.account_circle_outlined, size: 30),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const AccountScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FocusCard(onStart: onOpenFocus),
                ],
              ),
            ),
            if (library.recent.isNotEmpty) ...[
              _SectionTitle('Recently played'),
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: library.recent.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final t = library.recent[i];
                    return GestureDetector(
                      onTap: () => player.playFromList(library.recent, i),
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
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            _SectionTitle('Your songs'),
            if (library.tracks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('No songs yet. Add music from your phone to get started.'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => importSongs(context),
                        child: const Text('Add songs'),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (var i = 0; i < library.tracks.length && i < 6; i++)
                TrackTile(
                  track: library.tracks[i],
                  onTap: () => player.playFromList(library.tracks, i),
                  onFavorite: () => library.toggleFavorite(library.tracks[i]),
                  onMore: () => showTrackMenu(context, library.tracks[i]),
                ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Focus Mode',
                    style: TextStyle(
                        color: AppColors.terracotta,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                SizedBox(height: 2),
                Text('Music, ambient sounds and a timer',
                    style: TextStyle(color: AppColors.sage, fontSize: 13)),
              ],
            ),
          ),
          FilledButton(onPressed: onStart, child: const Text('Open')),
        ],
      ),
    );
  }
}
