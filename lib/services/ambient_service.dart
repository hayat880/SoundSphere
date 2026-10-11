import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../core/events/event_bus.dart';
import '../core/events/playback_events.dart';

class AmbientSound {
  const AmbientSound(this.id, this.name, this.asset, this.icon);
  final String id;
  final String name;
  final String asset;
  final IconData icon;
}

/// Plays looping ambient sounds, one player per sound.
/// Put matching audio files in assets/ambient/ (see the build guide).
class AmbientService extends ChangeNotifier {
  AmbientService(this._bus);
  final EventBus _bus;

  static const List<AmbientSound> sounds = [
    AmbientSound('light_rain', 'Light Rain', 'assets/ambient/light_rain.wav', Icons.grain),
    AmbientSound('heavy_rain', 'Heavy Rain', 'assets/ambient/heavy_rain.wav', Icons.water_drop),
    AmbientSound('thunderstorm', 'Thunderstorm', 'assets/ambient/thunderstorm.wav', Icons.flash_on),
    AmbientSound('ocean_waves', 'Ocean Waves', 'assets/ambient/ocean_waves.wav', Icons.waves),
    AmbientSound('crowd', 'Crowd Talking', 'assets/ambient/crowd.wav', Icons.groups),
    AmbientSound('bird', 'Birds Chirping', 'assets/ambient/bird.wav', Icons.flutter_dash),
    AmbientSound('airplane_cabin', 'Airplane Cabin', 'assets/ambient/airplane_cabin.wav', Icons.flight),
    AmbientSound('silent_train', 'Silent Train', 'assets/ambient/silent_train.wav', Icons.train),
    // More generated loops (seamless, no gap when they repeat).
    AmbientSound('white_noise', 'White Noise', 'assets/ambient/white_noise.wav', Icons.blur_on),
    AmbientSound('pink_noise', 'Pink Noise', 'assets/ambient/pink_noise.wav', Icons.graphic_eq),
    AmbientSound('brown_noise', 'Brown Noise', 'assets/ambient/brown_noise.wav', Icons.equalizer),
    AmbientSound('wind', 'Soft Wind', 'assets/ambient/wind.wav', Icons.air),
    AmbientSound('fireplace', 'Fireplace', 'assets/ambient/fireplace.wav', Icons.local_fire_department),
    AmbientSound('crickets', 'Night Crickets', 'assets/ambient/crickets.wav', Icons.nights_stay),
    AmbientSound('stream', 'Flowing Stream', 'assets/ambient/stream.wav', Icons.water),
  ];

  final Map<String, AudioPlayer> _players = {};
  final Set<String> _enabled = {};
  final Map<String, double> _volumes = {};

  /// True while a focus session owns the mix (sounds stay on until it ends).
  bool sessionActive = false;

  bool isEnabled(String id) => _enabled.contains(id);
  double volumeOf(String id) => _volumes[id] ?? 0.8;

  Future<void> toggle(String id, bool on) async {
    if (on) {
      _enabled.add(id);
      notifyListeners();
      await _startPlayer(id);
    } else {
      _enabled.remove(id);
      notifyListeners();
      await _stopPlayer(id);
    }
  }

  void setVolume(String id, double volume) {
    _volumes[id] = volume;
    _players[id]?.setVolume(volume);
    notifyListeners();
  }

  /// Starts every sound that is in the mix but not yet playing.
  Future<void> startEnabled() async {
    sessionActive = true;
    for (final id in _enabled.toList()) {
      await _startPlayer(id);
    }
  }

  /// Silences the preview played on the Ambient screen. The mix is kept, and
  /// a running focus session is left alone.
  Future<void> stopPreview() async {
    if (sessionActive) return;
    await stopAll();
  }

  Future<void> pauseAll() async {
    for (final p in _players.values.toList()) {
      await p.pause();
    }
  }

  Future<void> resumeAll() async {
    for (final p in _players.values.toList()) {
      p.play();
    }
  }

  Future<void> fadeOutAll({
    Duration duration = const Duration(seconds: 2),
  }) async {
    sessionActive = false;
    final snapshot = Map<String, AudioPlayer>.of(_players);
    if (snapshot.isEmpty) return;
    const steps = 10;
    for (var i = steps - 1; i >= 0; i--) {
      await Future<void>.delayed(duration ~/ steps);
      for (final entry in snapshot.entries) {
        entry.value.setVolume(volumeOf(entry.key) * i / steps);
      }
    }
    await stopAll();
  }

  Future<void> stopAll() async {
    sessionActive = false;
    for (final id in _players.keys.toList()) {
      await _stopPlayer(id);
    }
    notifyListeners();
  }

  Future<void> _startPlayer(String id) async {
    if (_players.containsKey(id)) return;
    final sound = sounds.firstWhere((s) => s.id == id);
    // These two flags stop the ambient players from taking audio focus,
    // which would otherwise pause the music player.
    final player = AudioPlayer(
      handleInterruptions: false,
      handleAudioSessionActivation: false,
    );
    _players[id] = player;
    try {
      await player.setAsset(sound.asset);
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(volumeOf(id));
      player.play();
    } catch (e) {
      debugPrint('Ambient sound "${sound.name}" failed: $e');
      _bus.publish(PlaybackFailed(
          'Could not load "${sound.name}": $e. Make sure assets/ambient/ is '
          'listed under assets in pubspec.yaml, then fully restart the app.'));
      _players.remove(id);
      await player.dispose();
    }
  }

  Future<void> _stopPlayer(String id) async {
    final player = _players.remove(id);
    if (player == null) return;
    await player.stop();
    await player.dispose();
  }
}
