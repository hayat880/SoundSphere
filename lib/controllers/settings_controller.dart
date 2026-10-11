import 'package:flutter/foundation.dart';

import '../core/events/event_bus.dart';
import '../core/events/focus_events.dart';
import '../core/events/library_events.dart';
import '../core/events/settings_events.dart';
import '../models/app_settings.dart';
import '../repositories/history_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/settings_repository.dart';

/// Holds the preferences for the Settings screen. Changing a preference only
/// publishes [SettingsChanged]; the handlers and controllers that care
/// (saving, focus timer, notifications) react on their own.
class SettingsController extends ChangeNotifier {
  SettingsController(this._bus, this._repo, this._history, this._sessions);
  final EventBus _bus;
  final SettingsRepository _repo;
  final HistoryRepository _history;
  final SessionRepository _sessions;

  AppSettings settings = const AppSettings();

  /// Reads the saved preferences and announces them so every listener
  /// starts with the right values.
  Future<void> load() async {
    settings = await _repo.load();
    notifyListeners();
    _bus.publish(SettingsChanged(settings));
  }

  void _update(AppSettings next) {
    settings = next;
    notifyListeners();
    _bus.publish(SettingsChanged(next));
  }

  void setNotifications(bool value) =>
      _update(settings.copyWith(notificationsEnabled: value));
  void setAutoBreak(bool value) =>
      _update(settings.copyWith(autoBreak: value));
  void setBreakSeconds(int seconds) =>
      _update(settings.copyWith(breakSeconds: seconds));
  void setFocusSeconds(int seconds) =>
      _update(settings.copyWith(focusSeconds: seconds));

  Future<void> clearListeningHistory() async {
    await _history.clear();
    _bus.publish(HistoryUpdated()); // LibraryController refreshes "Recently played"
  }

  Future<void> clearFocusHistory() async {
    await _sessions.clear();
    _bus.publish(FocusHistoryCleared()); // StatsController refreshes
  }
}
