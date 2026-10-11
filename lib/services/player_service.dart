import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../core/events/event_bus.dart';
import '../core/events/playback_events.dart';
import '../models/track.dart';

enum QueueRepeat { off, all, one }

/// Wraps the just_audio player. It owns the play queue, shuffle and repeat,
/// and publishes events about what the audio engine does.
class PlayerService {
  PlayerService(this._bus) {
    _player.playerStateStream.listen(_onPlayerState);
  }

  final EventBus _bus;
  final AudioPlayer _player = AudioPlayer();
  List<Track> _queue = [];
  List<Track> _original = []; // order before shuffling
  int _index = -1;
  bool _completionHandled = false;

  bool shuffleEnabled = false;
  QueueRepeat repeatMode = QueueRepeat.off;

  AudioPlayer get player => _player;
  bool get isPlaying => _player.playing;
  List<Track> get queue => List<Track>.unmodifiable(_queue);
  int get currentIndex => _index;
  Track? get current =>
      (_index >= 0 && _index < _queue.length) ? _queue[_index] : null;
  bool get hasNext => _index + 1 < _queue.length;
  bool get hasPrevious => _index > 0;

  // ---------- starting playback ----------

  Future<void> playQueue(List<Track> tracks, int index) async {
    if (tracks.isEmpty) return;
    final start =
        index < 0 ? 0 : (index >= tracks.length ? tracks.length - 1 : index);
    _original = List<Track>.of(tracks);
    if (shuffleEnabled) {
      final rest = List<Track>.of(tracks)..removeAt(start);
      rest.shuffle();
      _queue = [tracks[start], ...rest];
      _bus.publish(QueueChanged());
      await _playAt(0);
    } else {
      _queue = List<Track>.of(tracks);
      _bus.publish(QueueChanged());
      await _playAt(start);
    }
  }

  Future<void> playShuffled(List<Track> tracks) async {
    if (tracks.isEmpty) return;
    shuffleEnabled = true;
    await playQueue(tracks, Random().nextInt(tracks.length));
  }

  Future<void> _playAt(int index) async {
    _index = index;
    _completionHandled = false;
    final track = _queue[index];
    try {
      await _player.setVolume(1.0);
      if (track.isOnline) {
        await _player.setUrl(track.filePath);
      } else {
        await _player.setFilePath(track.filePath);
      }
      _player.play(); // not awaited on purpose: it finishes when the song ends
    } catch (e) {
      debugPrint('Could not play ${track.title}: $e');
      _bus.publish(PlaybackFailed('Could not play "${track.title}".'));
    }
    _bus.publish(PlaybackStateChanged(_player.playing, current));
  }

  void _onPlayerState(PlayerState state) {
    _bus.publish(PlaybackStateChanged(state.playing, current));
    if (state.processingState == ProcessingState.completed &&
        !_completionHandled) {
      _completionHandled = true;
      final track = current;
      if (track != null) _bus.publish(TrackPlaybackCompleted(track));
    }
  }

  /// Called when a song ends on its own. Respects repeat mode.
  Future<void> onTrackCompleted() async {
    if (repeatMode == QueueRepeat.one && current != null) {
      await _playAt(_index);
      return;
    }
    if (hasNext) {
      await _playAt(_index + 1);
      return;
    }
    if (repeatMode == QueueRepeat.all && _queue.isNotEmpty) {
      await _playAt(0);
      return;
    }
    await stop();
  }

  // ---------- transport controls ----------

  Future<void> next() async {
    if (hasNext) {
      await _playAt(_index + 1);
    } else if (repeatMode == QueueRepeat.all && _queue.isNotEmpty) {
      await _playAt(0);
    } else {
      await stop();
    }
  }

  Future<void> previous() async {
    if (_player.position > const Duration(seconds: 3) || !hasPrevious) {
      await _player.seek(Duration.zero);
    } else {
      await _playAt(_index - 1);
    }
  }

  Future<void> togglePlay() async {
    if (_player.playing) {
      await _player.pause();
    } else if (current != null) {
      _player.play();
    }
  }

  Future<void> pause() => _player.pause();

  void resume() {
    if (current != null) _player.play();
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> stop() async {
    await _player.stop();
    _bus.publish(PlaybackStateChanged(false, current));
  }

  Future<void> fadeOutAndStop({
    Duration duration = const Duration(seconds: 2),
  }) async {
    if (!_player.playing) return;
    const steps = 10;
    for (var i = steps - 1; i >= 0; i--) {
      await Future<void>.delayed(duration ~/ steps);
      await _player.setVolume(i / steps);
    }
    await _player.stop();
    await _player.setVolume(1.0);
    _bus.publish(PlaybackStateChanged(false, current));
  }

  // ---------- shuffle and repeat ----------

  void toggleShuffle() {
    final cur = current;
    shuffleEnabled = !shuffleEnabled;
    if (cur != null && _queue.length > 1) {
      if (shuffleEnabled) {
        _original = List<Track>.of(_queue);
        final rest = List<Track>.of(_queue)..removeAt(_index);
        rest.shuffle();
        _queue = [cur, ...rest];
        _index = 0;
      } else {
        final restored = List<Track>.of(_original);
        final at = restored.indexWhere((t) => t.id == cur.id);
        _queue = restored;
        _index = at < 0 ? 0 : at;
      }
    }
    _bus.publish(QueueChanged());
  }

  void cycleRepeat() {
    repeatMode = switch (repeatMode) {
      QueueRepeat.off => QueueRepeat.all,
      QueueRepeat.all => QueueRepeat.one,
      QueueRepeat.one => QueueRepeat.off,
    };
    _bus.publish(QueueChanged());
  }

  // ---------- queue management ----------

  void addToQueue(Track track) {
    if (_queue.isEmpty) {
      playQueue([track], 0);
      return;
    }
    _queue.add(track);
    _original = List<Track>.of(_queue);
    _bus.publish(QueueChanged());
  }

  void playNext(Track track) {
    if (_queue.isEmpty) {
      playQueue([track], 0);
      return;
    }
    _queue.insert(_index + 1, track);
    _original = List<Track>.of(_queue);
    _bus.publish(QueueChanged());
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length || index == _index) return;
    _queue.removeAt(index);
    if (index < _index) _index--;
    _original = List<Track>.of(_queue);
    _bus.publish(QueueChanged());
  }

  /// [newIndex] is the final position, already adjusted for the removed item
  /// (this is what ReorderableListView.onReorderItem gives you).
  void moveInQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _queue.length) return;
    var target = newIndex;
    if (target < 0) target = 0;
    if (target > _queue.length - 1) target = _queue.length - 1;
    final item = _queue.removeAt(oldIndex);
    _queue.insert(target, item);
    if (_index == oldIndex) {
      _index = target;
    } else if (oldIndex < _index && target >= _index) {
      _index--;
    } else if (oldIndex > _index && target <= _index) {
      _index++;
    }
    _original = List<Track>.of(_queue);
    _bus.publish(QueueChanged());
  }

  Future<void> jumpTo(int index) async {
    if (index < 0 || index >= _queue.length) return;
    await _playAt(index);
  }

  Future<void> dispose() => _player.dispose();
}
