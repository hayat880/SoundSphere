import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/events/event_bus.dart';
import '../core/events/playback_events.dart';
import '../models/track.dart';
import '../services/player_service.dart';

/// Controller for the player screens. Normal actions call the service
/// directly; choosing a song is published as an event.
class PlayerController extends ChangeNotifier {
  PlayerController(this._bus, this._service) {
    _subs.add(_bus.on<PlaybackStateChanged>().listen((e) {
      _isPlaying = e.isPlaying;
      _currentTrack = e.track;
      notifyListeners();
    }));
    _subs.add(_bus.on<QueueChanged>().listen((_) => notifyListeners()));
  }

  final EventBus _bus;
  final PlayerService _service;
  final List<StreamSubscription<dynamic>> _subs = [];

  bool _isPlaying = false;
  Track? _currentTrack;

  bool get isPlaying => _isPlaying;
  Track? get currentTrack => _currentTrack;
  List<Track> get queue => _service.queue;
  int get currentIndex => _service.currentIndex;
  bool get shuffleEnabled => _service.shuffleEnabled;
  QueueRepeat get repeatMode => _service.repeatMode;
  Stream<Duration> get positionStream => _service.player.positionStream;
  Stream<Duration?> get durationStream => _service.player.durationStream;

  void playFromList(List<Track> tracks, int index) =>
      _bus.publish(TrackSelected(tracks, index));

  void shufflePlay(List<Track> tracks) {
    if (tracks.isEmpty) return;
    _bus.publish(TrackSelected(tracks, 0, shuffle: true));
  }

  void togglePlay() => _service.togglePlay();
  void next() => _service.next();
  void previous() => _service.previous();
  void seek(Duration position) => _service.seek(position);
  void toggleShuffle() => _service.toggleShuffle();
  void cycleRepeat() => _service.cycleRepeat();
  void jumpTo(int index) => _service.jumpTo(index);
  void addToQueue(Track track) => _service.addToQueue(track);
  void playNext(Track track) => _service.playNext(track);
  void removeFromQueue(int index) => _service.removeFromQueue(index);
  void moveInQueue(int oldIndex, int newIndex) =>
      _service.moveInQueue(oldIndex, newIndex);

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
