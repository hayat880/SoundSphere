import 'dart:async';

import '../core/events/account_events.dart';
import '../core/events/break_events.dart';
import '../core/events/event_bus.dart';
import '../core/events/focus_events.dart';
import '../core/events/playback_events.dart';
import '../core/events/scan_events.dart';

/// Turns events into short messages the screen shows as a snack bar.
/// (System notifications can replace this later with flutter_local_notifications.)
class NotificationHandler {
  NotificationHandler(this._bus);
  final EventBus _bus;
  final StreamController<String> _messages =
      StreamController<String>.broadcast();
  final List<StreamSubscription<dynamic>> _subs = [];

  Stream<String> get messages => _messages.stream;

  void init() {
    dispose();
    _subs.add(_bus.on<FocusCompleted>().listen(
        (_) => _messages.add('Focus session complete. Time for a break!')));
    _subs.add(_bus.on<FocusCancelled>()
        .listen((_) => _messages.add('Focus session stopped.')));
    _subs.add(_bus.on<PlaybackFailed>().listen((e) => _messages.add(e.message)));
    _subs.add(_bus.on<BreakStarted>().listen(
        (e) => _messages.add('Break started: ${_label(e.breakSeconds)}. Rest your eyes.')));
    _subs.add(_bus.on<BreakCompleted>().listen(
        (_) => _messages.add('Break over. Ready for the next session?')));
    _subs.add(_bus
        .on<BreakSkipped>()
        .listen((_) => _messages.add('Break skipped.')));
    _subs.add(_bus.on<ScanCompleted>().listen((e) => _messages.add(e.added > 0
        ? 'Scan finished: ${e.added} new song${e.added == 1 ? '' : 's'} added.'
        : 'Scan finished: no new songs found.')));
    _subs.add(_bus
        .on<AccountUpdated>()
        .listen((_) => _messages.add('Profile updated.')));
  }

  String _label(int seconds) =>
      seconds < 60 ? '$seconds seconds' : '${seconds ~/ 60} minutes';

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }
}
