class FocusSession {
  const FocusSession({
    this.id,
    required this.startedAt,
    required this.plannedMinutes,
    required this.actualSeconds,
    required this.completed,
    this.playlistId,
  });

  final int? id;
  final DateTime startedAt;
  final int plannedMinutes;
  final int actualSeconds;
  final bool completed;
  final int? playlistId;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'started_at': startedAt.toIso8601String(),
        'planned_minutes': plannedMinutes,
        'actual_seconds': actualSeconds,
        'completed': completed ? 1 : 0,
        'playlist_id': playlistId,
      };

  factory FocusSession.fromMap(Map<String, Object?> m) => FocusSession(
        id: m['id'] as int?,
        startedAt: DateTime.parse(m['started_at'] as String),
        plannedMinutes: m['planned_minutes'] as int,
        actualSeconds: m['actual_seconds'] as int,
        completed: (m['completed'] as int) == 1,
        playlistId: m['playlist_id'] as int?,
      );
}
