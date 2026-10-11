import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/account_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../account/account_screen.dart';
import '../library/library_screen.dart';
import '../scan/scan_screen.dart';

class _Preset {
  const _Preset(this.label, this.seconds);
  final String label;
  final int seconds;
}

const List<_Preset> _focusPresets = [
  _Preset('Demo 10s', 10),
  _Preset('15 min', 900),
  _Preset('25 min', 1500),
  _Preset('45 min', 2700),
];

const List<_Preset> _breakPresets = [
  _Preset('Demo 5s', 5),
  _Preset('5 min', 300),
  _Preset('10 min', 600),
  _Preset('15 min', 900),
];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<bool> _confirm(BuildContext context, String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final settings = controller.settings;
    final account = context.watch<AccountController>();
    final messenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const _SectionTitle('Account'),
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(account.profile?.name ?? 'Offline mode'),
              subtitle: Text(account.profile?.email ??
                  'Your music and focus data stay on this device'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
              ),
            ),
            const _SectionTitle('Focus defaults'),
            const _Label('Session length'),
            _Chips(
              presets: _focusPresets,
              selected: settings.focusSeconds,
              onSelect: controller.setFocusSeconds,
            ),
            SwitchListTile(
              title: const Text('Start a break automatically'),
              subtitle: const Text('After each completed focus session'),
              value: settings.autoBreak,
              onChanged: controller.setAutoBreak,
            ),
            if (settings.autoBreak) ...[
              const _Label('Break length'),
              _Chips(
                presets: _breakPresets,
                selected: settings.breakSeconds,
                onSelect: controller.setBreakSeconds,
              ),
            ],
            const _SectionTitle('Notifications'),
            SwitchListTile(
              title: const Text('Phone notifications'),
              subtitle: const Text(
                  'Alert me when a session or break ends while the app is in the background'),
              value: settings.notificationsEnabled,
              onChanged: controller.setNotifications,
            ),
            const _SectionTitle('Library'),
            ListTile(
              leading: const Icon(Icons.manage_search),
              title: const Text('Scan phone for music'),
              subtitle:
                  const Text('Find songs in Music, Download and Documents'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ScanScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add songs'),
              subtitle: const Text('Choose audio files with the file picker'),
              onTap: () => importSongs(context),
            ),
            const _SectionTitle('Data'),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Clear listening history'),
              subtitle: const Text('Empties "Recently played"'),
              onTap: () async {
                final ok = await _confirm(context, 'Clear listening history?',
                    'Recently played will be emptied. Your songs and playlists stay.');
                if (!ok) return;
                await controller.clearListeningHistory();
                messenger.showSnackBar(
                    const SnackBar(content: Text('Listening history cleared')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer_off_outlined),
              title: const Text('Clear focus history'),
              subtitle: const Text('Deletes all saved focus sessions and stats'),
              onTap: () async {
                final ok = await _confirm(context, 'Clear focus history?',
                    'All saved focus sessions will be deleted. This cannot be undone.');
                if (!ok) return;
                await controller.clearFocusHistory();
                messenger.showSnackBar(
                    const SnackBar(content: Text('Focus history cleared')));
              },
            ),
            const _SectionTitle('About'),
            const ListTile(
              leading: Icon(Icons.headphones),
              title: Text('SoundSphere'),
              subtitle: Text(
                  'Music · Focus · Balance\nBuilt with MVC + Event-Driven Architecture'),
              isThreeLine: true,
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.moss,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({
    required this.presets,
    required this.selected,
    required this.onSelect,
  });

  final List<_Preset> presets;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          for (final p in presets)
            ChoiceChip(
              label: Text(p.label),
              selected: selected == p.seconds,
              showCheckmark: false,
              onSelected: (_) => onSelect(p.seconds),
              selectedColor: AppColors.terracotta,
              backgroundColor: AppColors.chip,
              side: BorderSide.none,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected == p.seconds
                    ? AppColors.forest
                    : AppColors.moss,
              ),
            ),
        ],
      ),
    );
  }
}
