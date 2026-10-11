import 'dart:async';

import '../core/events/event_bus.dart';
import '../core/events/focus_events.dart';
import '../models/focus_session.dart';
import '../repositories/session_repository.dart';

/// Saves focus sessions to the database when they end.
class SessionHandler {
  SessionHandler(this._bus, this._repo);
  final EventBus _bus;
  final SessionRepository _repo;
  final List<StreamSubscription<dynamic>> _subs = [];

  // Only real playlists (id > 0) can be stored; "All songs" and
  // "Liked Songs" are saved without a playlist.
  int? _realId(int? id) => (id != null && id > 0) ? id : null;

  void init() {
    dispose();
    _subs.add(_bus.on<FocusCompleted>().listen((e) => _save(FocusSession(
          startedAt: e.startedAt,
          plannedMinutes: (e.plannedSeconds / 60).ceil(),
          actualSeconds: e.plannedSeconds,
          completed: true,
          playlistId: _realId(e.playlistId),
        ))));
    _subs.add(_bus.on<FocusCancelled>().listen((e) {
      if (e.elapsedSeconds < 1) return;
      _save(FocusSession(
        startedAt: e.startedAt,
        plannedMinutes: (e.plannedSeconds / 60).ceil(),
        actualSeconds: e.elapsedSeconds,
        completed: false,
        playlistId: _realId(e.playlistId),
      ));
    }));
  }

  Future<void> _save(FocusSession session) async {
    final saved = await _repo.save(session);
    if (saved) _bus.publish(SessionSaved(session));
  }

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }
}
