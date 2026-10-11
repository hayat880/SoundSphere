import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/library_controller.dart';
import '../../controllers/player_controller.dart';
import '../../core/theme/app_colors.dart';
import '../online/online_screen.dart';
import '../widgets/track_menu.dart';
import '../widgets/track_tile.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final player = context.read<PlayerController>();
    final results = library.filtered;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: TextField(
                onChanged: library.setQuery,
                decoration: InputDecoration(
                  hintText: 'Search songs and artists',
                  prefixIcon: const Icon(Icons.search),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
              child: Text(
                library.query.trim().isEmpty ? 'All songs' : 'Results',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            library.tracks.isEmpty
                                ? 'Add songs in the Library tab first.'
                                : 'No songs match your search.',
                            style: const TextStyle(color: AppColors.moss),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                    builder: (_) => const OnlineScreen())),
                            icon: const Icon(Icons.cloud_outlined),
                            label: const Text('Search online instead'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, i) => TrackTile(
                        track: results[i],
                        onTap: () => player.playFromList(results, i),
                        onFavorite: () => library.toggleFavorite(results[i]),
                        onMore: () => showTrackMenu(context, results[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
