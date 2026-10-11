import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/scan_controller.dart';
import '../../core/theme/app_colors.dart';

/// Scans the phone's Music, Download and Documents folders for songs.
class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scan = context.watch<ScanController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan for music')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.forest,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.library_music,
                    size: 46, color: AppColors.terracotta),
              ),
            ),
            const SizedBox(height: 20),
            Text('Find the music already on your phone',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'SoundSphere looks in your Music, Download and Documents folders '
              'and adds every song it finds. Files are not copied. Artist and '
              'album come from the file and folder names '
              '(for example Music/Artist/Album/01 - Song.mp3).',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.moss),
            ),
            const SizedBox(height: 28),
            _StatusArea(scan: scan),
          ],
        ),
      ),
    );
  }
}

class _StatusArea extends StatelessWidget {
  const _StatusArea({required this.scan});
  final ScanController scan;

  @override
  Widget build(BuildContext context) {
    switch (scan.status) {
      case ScanStatus.idle:
        return FilledButton.icon(
          onPressed: scan.start,
          icon: const Icon(Icons.search),
          label: const Text('Start scan'),
        );
      case ScanStatus.requesting:
        return const Column(children: [
          LinearProgressIndicator(),
          SizedBox(height: 12),
          Text('Waiting for permission…',
              style: TextStyle(color: AppColors.moss)),
        ]);
      case ScanStatus.scanning:
        return Column(children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 14),
          Text('${scan.found} song${scan.found == 1 ? '' : 's'} found',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          if (scan.currentFolder.isNotEmpty)
            Text(scan.currentFolder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.moss)),
        ]);
      case ScanStatus.done:
        return Column(children: [
          const Icon(Icons.check_circle, color: AppColors.olive, size: 40),
          const SizedBox(height: 8),
          Text(
              scan.added > 0
                  ? '${scan.added} new song${scan.added == 1 ? '' : 's'} added'
                  : 'No new songs found',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          Text('${scan.found} audio files checked',
              style: const TextStyle(color: AppColors.moss)),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: scan.start, child: const Text('Scan again')),
        ]);
      case ScanStatus.denied:
        return Column(children: [
          const Text(
            'SoundSphere needs permission to read your music files.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: scan.start, child: const Text('Allow access')),
        ]);
      case ScanStatus.permanentlyDenied:
        return Column(children: [
          const Text(
            'Permission was turned off. Open the app settings and allow '
            'access to music and audio.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: scan.openSettings,
              child: const Text('Open app settings')),
        ]);
      case ScanStatus.failed:
        return Column(children: [
          const Text('The scan stopped because of an error.',
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: scan.start, child: const Text('Try again')),
        ]);
    }
  }
}
