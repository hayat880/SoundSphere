import 'dart:async';

import '../core/events/event_bus.dart';
import '../core/events/library_events.dart';
import '../core/events/playback_events.dart';
import '../repositories/history_repository.dart';

/// Writes one history row each time a song finishes playing.
class HistoryHandler {
  HistoryHandler(this._bus, this._repo);
  final EventBus _bus;
  final HistoryRepository _repo;
  StreamSubscription<dynamic>? _sub;

  void init() {
    dispose();
    _sub = _bus.on<TrackPlaybackCompleted>().listen((e) async {
      final id = e.track.id;
      if (id == null) return;
      await _repo.add(id, e.track.durationMs ~/ 1000);
      _bus.publish(HistoryUpdated());
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
