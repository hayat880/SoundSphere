import 'dart:async';

import '../core/events/event_bus.dart';
import '../core/events/library_events.dart';
import '../core/events/playback_events.dart';
import '../repositories/track_repository.dart';

/// Saves favorite changes, then announces that the library changed.
class FavoriteHandler {
  FavoriteHandler(this._bus, this._repo);
  final EventBus _bus;
  final TrackRepository _repo;
  StreamSubscription<dynamic>? _sub;

  void init() {
    dispose();
    _sub = _bus.on<FavoriteChanged>().listen((e) async {
      await _repo.setFavorite(e.trackId, e.isFavorite);
      _bus.publish(LibraryUpdated(0));
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
