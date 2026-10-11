import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/playlist_controller.dart';
import '../../controllers/stats_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../models/focus_session.dart';

enum _Filter { all, completed, stopped }

/// Every focus session, newest first, grouped by day. Swipe a row left to
/// delete it.
class FocusHistoryScreen extends StatefulWidget {
  const FocusHistoryScreen({super.key});

  @override
  State<FocusHistoryScreen> createState() => _FocusHistoryScreenState();
}

class _FocusHistoryScreenState extends State<FocusHistoryScreen> {
  _Filter _filter = _Filter.all;

  static String _two(int n) => n.toString().padLeft(2, '0');

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _dayLabel(DateTime day) {
    final today = _day(DateTime.now());
    if (day == today) return 'Today';
    if (day == DateTime(today.year, today.month, today.day - 1)) {
      return 'Yesterday';
    }
    return '${day.day}/${day.month}/${day.year}';
  }

  @override
  void initState() {
    super.initState();
    final stats = context.read<StatsController>();
    Future.microtask(stats.refresh);
  }

  String _playlistName(int? id) {
    if (id == null) return 'All songs';
    for (final p in context.read<PlaylistController>().playlists) {
      if (p.id == id) return p.name;
    }
    return 'Deleted playlist';
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsController>();
    context.watch<PlaylistController>(); // refresh names after a rename
    final theme = Theme.of(context);

    final sessions = stats.sessions.where((s) {
      switch (_filter) {
        case _Filter.all:
          return true;
        case _Filter.completed:
          return s.completed;
        case _Filter.stopped:
          return !s.completed;
      }
    }).toList();

    // Flatten into: day header, its sessions, next day header, ...
    final items = <Object>[];
    DateTime? currentDay;
    for (final s in sessions) {
      final day = _day(s.startedAt);
      if (day != currentDay) {
        currentDay = day;
        items.add(day);
      }
      items.add(s);
    }
    final totalSeconds =
        sessions.fold<int>(0, (sum, s) => sum + s.actualSeconds);

    return Scaffold(
      appBar: AppBar(title: const Text('Focus history')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Row(
                children: [
                  for (final f in _Filter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(switch (f) {
                          _Filter.all => 'All',
                          _Filter.completed => 'Completed',
                          _Filter.stopped => 'Stopped',
                        }),
                        selected: _filter == f,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _filter = f),
                        selectedColor: AppColors.terracotta,
                        backgroundColor: AppColors.chip,
                        side: BorderSide.none,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _filter == f
                              ? AppColors.forest
                              : AppColors.moss,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                '${sessions.length} session${sessions.length == 1 ? '' : 's'} · ${durationLabel(totalSeconds)} focused',
                style: const TextStyle(color: AppColors.moss),
              ),
            ),
            Expanded(
              child: sessions.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No sessions here yet. Start a focus session to see it in your history.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.moss),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        if (item is DateTime) {
                          final dayTotal = sessions
                              .where((s) => _day(s.startedAt) == item)
                              .fold<int>(0, (sum, s) => sum + s.actualSeconds);
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                            child: Row(
                              children: [
                                Text(_dayLabel(item),
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700)),
                                const Spacer(),
                                Text(durationLabel(dayTotal),
                                    style: const TextStyle(
                                        color: AppColors.moss)),
                              ],
                            ),
                          );
                        }
                        return _row(stats, item as FocusSession);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(StatsController stats, FocusSession s) {
    final d = s.startedAt;
    final title = s.completed
        ? '${durationLabel(s.actualSeconds)} · Completed'
        : '${durationLabel(s.actualSeconds)} of ${durationLabel(s.plannedMinutes * 60)} · Stopped';
    return Dismissible(
      key: ValueKey<Object>(s.id ?? s.startedAt),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.terracotta,
        child: const Icon(Icons.delete_outline, color: AppColors.forest),
      ),
      onDismissed: (_) => stats.delete(s),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: s.completed ? AppColors.forest : AppColors.chip,
              child: Icon(
                s.completed ? Icons.check : Icons.close,
                color: s.completed ? AppColors.terracotta : AppColors.moss,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  Text('${_two(d.hour)}:${_two(d.minute)} · ${_playlistName(s.playlistId)}',
                      style: const TextStyle(
                          color: AppColors.moss, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
