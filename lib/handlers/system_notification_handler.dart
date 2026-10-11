import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/events/break_events.dart';
import '../core/events/event_bus.dart';
import '../core/events/focus_events.dart';
import '../core/events/settings_events.dart';
import '../services/system_notification_service.dart';

/// Shows phone (system) notifications for focus and break alerts, but only
/// while the app is NOT on screen. When the app is open, the in-app snack bar
/// from NotificationHandler is enough, so the user never sees both.
class SystemNotificationHandler {
  SystemNotificationHandler(this._bus, this._service);
  final EventBus _bus;
  final SystemNotificationService _service;
  final List<StreamSubscription<dynamic>> _subs = [];

  /// Set from Settings → Notifications.
  bool enabled = true;

  static const int _focusId = 1;
  static const int _breakId = 2;

  bool get _appInBackground {
    final state = WidgetsBinding.instance.lifecycleState;
    return state != null && state != AppLifecycleState.resumed;
  }

  void init() {
    dispose(); // never subscribe twice
    // Ask for permission the first time a session starts (Android 13+).
    _subs.add(_bus
        .on<SettingsChanged>()
        .listen((e) => enabled = e.settings.notificationsEnabled));
    _subs.add(_bus.on<FocusStarted>().listen((_) {
      if (enabled) _service.requestPermission();
    }));
    _subs.add(_bus.on<FocusCompleted>().listen((_) {
      if (enabled && _appInBackground) {
        _service.show(_focusId, 'Focus session complete',
            'Great work! Time for a break.');
      }
    }));
    _subs.add(_bus.on<BreakCompleted>().listen((_) {
      if (enabled && _appInBackground) {
        _service.show(_breakId, 'Break over', 'Ready for the next session?');
      }
    }));
  }

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }
}
