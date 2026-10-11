import 'dart:async';

import '../core/events/account_events.dart';
import '../core/events/event_bus.dart';
import '../core/events/focus_events.dart';
import '../core/events/playback_events.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../repositories/playlist_repository.dart';
import '../repositories/track_repository.dart';
import '../services/player_service.dart';

/// Reacts to events by controlling the music player.
class PlayerHandler {
  PlayerHandler(this._bus, this._service, this._tracks, this._playlists);
  final EventBus _bus;
  final PlayerService _service;
  final TrackRepository _tracks;
  final PlaylistRepository _playlists;
  final List<StreamSubscription<dynamic>> _subs = [];

  /// Repeat mode to put back after a one-song focus session.
  QueueRepeat? _repeatBeforeFocus;

  void init() {
    dispose(); // makes sure we never subscribe twice
    _subs.add(_bus.on<TrackSelected>().listen((e) {
      if (e.shuffle) {
        _service.playShuffled(e.queue);
      } else {
        _service.playQueue(e.queue, e.index);
      }
    }));
    _subs.add(_bus
        .on<TrackPlaybackCompleted>()
        .listen((_) => _service.onTrackCompleted()));
    _subs.add(_bus.on<FocusStarted>().listen(_onFocusStarted));
    _subs.add(_bus.on<FocusMusicChanged>().listen(_onMusicChanged));
    _subs.add(_bus.on<FocusPaused>().listen((_) => _service.pause()));
    _subs.add(_bus.on<FocusResumed>().listen((_) => _service.resume()));
    _subs.add(_bus.on<FocusCompleted>().listen((_) {
      _service.fadeOutAndStop().whenComplete(_restoreRepeat);
    }));
    _subs.add(_bus.on<FocusCancelled>().listen((_) {
      _service.stop();
      _restoreRepeat();
    }));
    // Logging out stops the music.
    _subs.add(_bus.on<AccountLoggedOut>().listen((_) {
      _service.stop();
      _restoreRepeat();
    }));
  }

  void _restoreRepeat() {
    final before = _repeatBeforeFocus;
    if (before == null) return;
    _repeatBeforeFocus = null;
    _service.repeatMode = before;
    _bus.publish(QueueChanged());
  }

  Future<void> _onFocusStarted(FocusStarted e) =>
      _startMusic(e.playlistId, e.trackId);

  /// The person picked different music in the middle of a session.
  Future<void> _onMusicChanged(FocusMusicChanged e) async {
    await _startMusic(e.playlistId, e.trackId, force: true);
    if (e.paused) await _service.pause();
  }

  Future<void> _startMusic(int? playlistId, int? trackId,
      {bool force = false}) async {
    // One chosen song: play it and repeat it until the session ends.
    if (trackId != null) {
      final all = await _tracks.all();
      final matches = all.where((t) => t.id == trackId).toList();
      if (matches.isEmpty) {
        _bus.publish(PlaybackFailed('That song is no longer in your library.'));
        return;
      }
      _repeatBeforeFocus ??= _service.repeatMode;
      _service.repeatMode = QueueRepeat.one;
      await _service.playQueue(matches, 0);
      return;
    }
    // Back to a list: stop repeating a single song.
    _restoreRepeat();
    // "All songs" and music already playing: just keep it going.
    if (!force && playlistId == null && _service.isPlaying) return;
    final tracks = await _loadTracks(playlistId);
    if (tracks.isEmpty) {
      _bus.publish(PlaybackFailed(
          'No songs to play. Add songs in the Library first.'));
      return;
    }
    await _service.playQueue(tracks, 0);
  }

  Future<List<Track>> _loadTracks(int? playlistId) async {
    if (playlistId == null) return _tracks.all();
    if (playlistId == kLikedPlaylistId) {
      final all = await _tracks.all();
      return all.where((t) => t.isFavorite).toList();
    }
    return _playlists.tracksOf(playlistId);
  }

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }
}
