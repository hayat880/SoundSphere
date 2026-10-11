import 'dart:async';

import '../core/events/event_bus.dart';
import '../core/events/settings_events.dart';
import '../repositories/settings_repository.dart';

/// Independent listener: saves preferences whenever they change. The
/// SettingsController does not know it exists.
class SettingsHandler {
  SettingsHandler(this._bus, this._repo);
  final EventBus _bus;
  final SettingsRepository _repo;
  StreamSubscription<SettingsChanged>? _sub;

  void init() {
    dispose(); // never subscribe twice
    _sub = _bus.on<SettingsChanged>().listen((e) => _repo.save(e.settings));
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
