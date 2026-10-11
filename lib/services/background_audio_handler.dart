import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../core/events/event_bus.dart';
import '../core/events/playback_events.dart';
import 'player_service.dart';

/// Connects the music player to Android's media session so playback keeps
/// going with the screen off and the app in the background, with
/// notification and lock-screen controls and headset buttons.
///
/// It follows the architecture: it only *reacts* to what the player does
/// (the player's own state stream and [PlaybackStateChanged] events) and
/// forwards button presses to [PlayerService]. Only the music player is
/// attached; the ambient players stay independent plain just_audio players.
class SoundSphereAudioHandler extends BaseAudioHandler with SeekHandler {
  SoundSphereAudioHandler(this._service, this._bus) {
    _subs.add(_service.player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object _, StackTrace __) {},
    ));
    _subs.add(_bus.on<PlaybackStateChanged>().listen(_onPlaybackEvent));
    _subs.add(_service.player.durationStream.listen(_onDuration));
  }

  final PlayerService _service;
  final EventBus _bus;
  final List<StreamSubscription<dynamic>> _subs = [];
  int? _shownTrackId;
  String? _shownPath;

  // ---------- from the app to the system ----------

  void _onPlaybackEvent(PlaybackStateChanged e) {
    final track = e.track;
    if (track == null) return;
    // Only update the notification when the song changes.
    if (_shownTrackId == track.id && _shownPath == track.filePath) return;
    _shownTrackId = track.id;
    _shownPath = track.filePath;
    mediaItem.add(MediaItem(
      id: track.filePath,
      title: track.title,
      artist: track.artist,
      album: track.album,
      duration:
          track.durationMs > 0 ? Duration(milliseconds: track.durationMs) : null,
    ));
  }

  void _onDuration(Duration? duration) {
    final item = mediaItem.value;
    if (item == null || duration == null) return;
    mediaItem.add(item.copyWith(duration: duration));
  }

  void _broadcastState(PlaybackEvent event) {
    final player = _service.player;
    final playing = player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
    ));
  }

  // ---------- from the system to the app ----------

  @override
  Future<void> play() async => _service.resume();

  @override
  Future<void> pause() => _service.pause();

  @override
  Future<void> seek(Duration position) => _service.seek(position);

  @override
  Future<void> skipToNext() => _service.next();

  @override
  Future<void> skipToPrevious() => _service.previous();

  @override
  Future<void> stop() async {
    await _service.stop();
    await super.stop();
  }

  Future<void> disposeHandler() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }
}
