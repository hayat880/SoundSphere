import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/stats_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../models/focus_session.dart';
import 'focus_history_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    final stats = context.read<StatsController>();
    Future.microtask(stats.refresh);
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsController>();
    final theme = Theme.of(context);
    final days = stats.last7DaysSeconds;
    final maxDay = days.fold<int>(1, (m, v) => v > m ? v : m);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Your focus')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.forest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Today', style: TextStyle(color: AppColors.sage)),
                  Text(durationLabel(stats.todaySeconds),
                      style: const TextStyle(
                          color: AppColors.terracotta,
                          fontSize: 44,
                          fontWeight: FontWeight.w700)),
                  Text(
                      '${stats.totalSessions} sessions in total, ${stats.completedSessions} completed',
                      style: const TextStyle(color: AppColors.sage)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatCard('Sessions', '${stats.totalSessions}'),
                const SizedBox(width: 10),
                _StatCard('Completed', '${stats.completedSessions}'),
                const SizedBox(width: 10),
                _StatCard('Streak', '${stats.streakDays} days'),
              ],
            ),
            const SizedBox(height: 20),
            Text('Last 7 days',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: days[i] == 0 ? 4 : 100 * days[i] / maxDay,
                              decoration: BoxDecoration(
                                color: i == 6
                                    ? AppColors.terracotta
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'MTWTFSS'[DateTime(now.year, now.month,
                                          now.day - (6 - i))
                                      .weekday -
                                  1],
                              style: const TextStyle(
                                  color: AppColors.moss, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text('Recent sessions',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const FocusHistoryScreen()),
                  ),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.terracotta),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (stats.recent.isEmpty)
              const Text('No sessions yet. Start a focus session to see it here.',
                  style: TextStyle(color: AppColors.moss))
            else
              for (final s in stats.recent) _SessionRow(s),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(color: AppColors.moss, fontSize: 13)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow(this.session);
  final FocusSession session;

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final d = session.startedAt;
    final title = session.completed
        ? '${durationLabel(session.actualSeconds)} · Completed'
        : '${durationLabel(session.actualSeconds)} of ${durationLabel(session.plannedMinutes * 60)} · Stopped';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                session.completed ? AppColors.forest : AppColors.chip,
            child: Icon(
              session.completed ? Icons.check : Icons.close,
              color: session.completed ? AppColors.terracotta : AppColors.moss,
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
                Text(
                    '${d.day}/${d.month}/${d.year}  ${_two(d.hour)}:${_two(d.minute)}',
                    style: const TextStyle(color: AppColors.moss, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
