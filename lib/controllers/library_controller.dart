import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/events/event_bus.dart';
import '../core/events/library_events.dart';
import '../core/events/playback_events.dart';
import '../models/track.dart';
import '../models/track_group.dart';
import '../repositories/history_repository.dart';
import '../repositories/track_repository.dart';
import '../services/import_service.dart';

class LibraryController extends ChangeNotifier {
  LibraryController(this._bus, this._tracks, this._history, this._import) {
    _subs.add(_bus.on<LibraryUpdated>().listen((_) => load()));
    _subs.add(_bus.on<HistoryUpdated>().listen((_) => load()));
  }

  final EventBus _bus;
  final TrackRepository _tracks;
  final HistoryRepository _history;
  final ImportService _import;
  final List<StreamSubscription<dynamic>> _subs = [];

  List<Track> tracks = [];
  List<Track> recent = [];
  List<Track> mostPlayed = [];
  String query = '';

  List<Track> get filtered {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return tracks;
    return tracks
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.artist.toLowerCase().contains(q))
        .toList();
  }

  /// Songs grouped by album / artist for the Albums and Artists tabs.
  List<TrackGroup> get albums => groupTracks(tracks, (t) => t.album);
  List<TrackGroup> get artists => groupTracks(tracks, (t) => t.artist);

  // ---- Explore ----
  List<Track> get newlyAdded => recentlyAdded(tracks);
  List<Track> get liked => tracks.where((t) => t.isFavorite).toList();
  List<TrackGroup> get popularArtists => topArtists(artists);

  Track? byId(int? id) {
    if (id == null) return null;
    for (final t in tracks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> load() async {
    tracks = await _tracks.all();
    recent = await _history.recentTracks();
    mostPlayed = await _history.mostPlayedTracks();
    notifyListeners();
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  Future<int> addSongs() => _import.pickAndImport();

  void toggleFavorite(Track track) {
    final id = track.id;
    if (id == null) return;
    // Always use the latest saved value, never an old copy of the track.
    final latest = byId(id) ?? track;
    _bus.publish(FavoriteChanged(id, !latest.isFavorite));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
