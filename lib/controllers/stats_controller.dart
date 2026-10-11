import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/events/event_bus.dart';
import '../core/events/focus_events.dart';
import '../models/focus_session.dart';
import '../repositories/session_repository.dart';

class StatsController extends ChangeNotifier {
  StatsController(this._bus, this._repo) {
    _subs.add(_bus.on<SessionSaved>().listen((_) => refresh()));
    _subs.add(_bus.on<FocusHistoryCleared>().listen((_) => refresh()));
  }
  final EventBus _bus;
  final SessionRepository _repo;
  final List<StreamSubscription<dynamic>> _subs = [];

  List<FocusSession> sessions = [];

  Future<void> refresh() async {
    sessions = await _repo.all();
    notifyListeners();
  }

  /// Removes one session (swipe to delete in Focus History). The list is
  /// updated first so the swiped row disappears immediately.
  Future<void> delete(FocusSession session) async {
    final id = session.id;
    if (id == null) return;
    sessions = sessions.where((s) => s.id != id).toList();
    notifyListeners();
    await _repo.delete(id);
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  int get todaySeconds {
    final today = _day(DateTime.now());
    return sessions
        .where((s) => _day(s.startedAt) == today)
        .fold<int>(0, (sum, s) => sum + s.actualSeconds);
  }

  int get totalSessions => sessions.length;
  int get completedSessions => sessions.where((s) => s.completed).length;

  int get streakDays {
    final days = sessions
        .where((s) => s.completed)
        .map((s) => _day(s.startedAt))
        .toSet();
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    if (!days.contains(day)) day = DateTime(day.year, day.month, day.day - 1);
    var count = 0;
    while (days.contains(day)) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  /// Seconds studied on each of the last 7 days, oldest first.
  List<int> get last7DaysSeconds {
    final now = DateTime.now();
    return List<int>.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day - (6 - i));
      return sessions
          .where((s) => _day(s.startedAt) == day)
          .fold<int>(0, (sum, s) => sum + s.actualSeconds);
    });
  }

  List<FocusSession> get recent => sessions.take(5).toList();

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
