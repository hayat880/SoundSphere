import 'package:flutter/foundation.dart';

import '../core/events/ambient_events.dart';
import '../core/events/event_bus.dart';
import '../services/ambient_service.dart';

class AmbientController extends ChangeNotifier {
  AmbientController(this._bus, this._service) {
    _service.addListener(notifyListeners);
  }
  final EventBus _bus;
  final AmbientService _service;

  List<AmbientSound> get sounds => AmbientService.sounds;
  bool isOn(String id) => _service.isEnabled(id);
  double volumeOf(String id) => _service.volumeOf(id);

  /// Called when the Ambient screen closes: stops the preview if no focus
  /// session is running.
  void stopPreview() => _service.stopPreview();

  void toggle(String id) => _bus.publish(AmbientSoundToggled(id, !isOn(id)));
  void setVolume(String id, double volume) =>
      _bus.publish(AmbientVolumeChanged(id, volume));

  @override
  void dispose() {
    _service.removeListener(notifyListeners);
    super.dispose();
  }
}
