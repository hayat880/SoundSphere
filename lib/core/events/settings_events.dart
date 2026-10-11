import '../../models/app_settings.dart';
import 'app_event.dart';

/// The user changed a preference (or the saved ones were loaded at start).
class SettingsChanged extends AppEvent {
  SettingsChanged(this.settings);
  final AppSettings settings;
}
