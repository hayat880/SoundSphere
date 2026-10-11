import 'app_event.dart';

class AmbientSoundToggled extends AppEvent {
  AmbientSoundToggled(this.soundId, this.isOn);
  final String soundId;
  final bool isOn;
}

class AmbientVolumeChanged extends AppEvent {
  AmbientVolumeChanged(this.soundId, this.volume);
  final String soundId;
  final double volume;
}
