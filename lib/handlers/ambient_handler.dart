import 'dart:async';

import '../core/events/account_events.dart';
import '../core/events/ambient_events.dart';
import '../core/events/event_bus.dart';
import '../core/events/focus_events.dart';
import '../services/ambient_service.dart';

/// Reacts to events by controlling the ambient sound layers.
class AmbientHandler {
  AmbientHandler(this._bus, this._service);
  final EventBus _bus;
  final AmbientService _service;
  final List<StreamSubscription<dynamic>> _subs = [];

  void init() {
    dispose();
    _subs.add(_bus.on<AmbientSoundToggled>().listen(
        (e) => _service.toggle(e.soundId, e.isOn)));
    _subs.add(_bus.on<AmbientVolumeChanged>().listen(
        (e) => _service.setVolume(e.soundId, e.volume)));
    _subs.add(_bus.on<FocusStarted>().listen((_) => _service.startEnabled()));
    _subs.add(_bus.on<FocusPaused>().listen((_) => _service.pauseAll()));
    _subs.add(_bus.on<FocusResumed>().listen((_) => _service.resumeAll()));
    _subs.add(_bus.on<FocusCompleted>().listen((_) => _service.fadeOutAll()));
    _subs.add(_bus.on<FocusCancelled>().listen((_) => _service.stopAll()));
    // Logging out silences the ambient mix.
    _subs.add(_bus.on<AccountLoggedOut>().listen((_) => _service.stopAll()));
  }

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }
}
