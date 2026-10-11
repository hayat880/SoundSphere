import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/events/account_events.dart';
import '../core/events/break_events.dart';
import '../core/events/event_bus.dart';
import '../core/events/focus_events.dart';
import '../core/events/settings_events.dart';
import '../models/app_settings.dart';

enum FocusStatus { idle, running, paused }

/// Runs the Pomodoro timer. It only publishes events: it has no idea
/// which handlers (music, ambient, database, alerts) react to them.
class FocusController extends ChangeNotifier {
  FocusController(this._bus) {
    // Logging out ends any running session or break.
    _logoutSub = _bus.on<AccountLoggedOut>().listen((_) {
      stop();
      skipBreak();
    });
    // Settings → default session length, auto-break and break length.
    _settingsSub = _bus
        .on<SettingsChanged>()
        .listen((e) => applySettings(e.settings));
  }
  final EventBus _bus;
  StreamSubscription<AccountLoggedOut>? _logoutSub;
  StreamSubscription<SettingsChanged>? _settingsSub;
  AppSettings? _lastSettings;

  /// Applies only the preferences that actually changed, so a session length
  /// picked on the Focus screen is not reset when an unrelated setting
  /// (for example notifications) is toggled.
  void applySettings(AppSettings s) {
    final last = _lastSettings;
    _lastSettings = s;
    if (last == null || last.autoBreak != s.autoBreak) autoBreak = s.autoBreak;
    if ((last == null || last.breakSeconds != s.breakSeconds) && !onBreak) {
      breakSeconds = s.breakSeconds;
    }
    if ((last == null || last.focusSeconds != s.focusSeconds) &&
        status == FocusStatus.idle &&
        !onBreak) {
      selectedSeconds = s.focusSeconds;
      remainingSeconds = s.focusSeconds;
    }
    notifyListeners();
  }

  FocusStatus status = FocusStatus.idle;
  int selectedSeconds = 25 * 60;
  int remainingSeconds = 25 * 60;

  /// null = all songs, kLikedPlaylistId = liked songs, otherwise a playlist id.
  int? selectedPlaylistId;
  String playlistName = 'All songs';

  /// When set, this one song plays (and repeats) for the whole session.
  int? selectedTrackId;

  // ---- break timer ----
  /// When true, a break starts automatically after each completed session.
  bool autoBreak = true;
  int breakSeconds = 5 * 60;
  bool onBreak = false;
  int breakRemaining = 0;
  Timer? _breakTimer;

  /// What the ring should show: the break countdown while on a break.
  int get displaySeconds => onBreak ? breakRemaining : remainingSeconds;
  int get displayTotal => onBreak ? breakSeconds : selectedSeconds;
  double get displayProgress =>
      displayTotal == 0 ? 0 : 1 - displaySeconds / displayTotal;

  void selectBreakSeconds(int seconds) {
    if (onBreak) return;
    breakSeconds = seconds;
    notifyListeners();
  }

  void setAutoBreak(bool value) {
    autoBreak = value;
    notifyListeners();
  }

  void _startBreak() {
    onBreak = true;
    breakRemaining = breakSeconds;
    _bus.publish(BreakStarted(breakSeconds));
    _breakTimer?.cancel();
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      breakRemaining--;
      if (breakRemaining <= 0) {
        timer.cancel();
        onBreak = false;
        _bus.publish(BreakCompleted(breakSeconds));
      }
      notifyListeners();
    });
  }

  /// Ends the break early.
  void skipBreak() {
    if (!onBreak) return;
    _breakTimer?.cancel();
    onBreak = false;
    _bus.publish(BreakSkipped());
    notifyListeners();
  }

  int? _runPlaylistId;
  int? _runTrackId;
  DateTime? _startedAt;
  Timer? _timer;

  double get progress =>
      selectedSeconds == 0 ? 0 : 1 - remainingSeconds / selectedSeconds;

  void selectSeconds(int seconds) {
    if (status != FocusStatus.idle || onBreak) return;
    selectedSeconds = seconds;
    remainingSeconds = seconds;
    notifyListeners();
  }

  void selectPlaylist(int? id, String name) {
    selectedPlaylistId = id;
    selectedTrackId = null;
    playlistName = name;
    _announceMusicChange();
    notifyListeners();
  }

  /// Plays one chosen song (repeating) instead of a list.
  void selectTrack(int id, String title) {
    selectedTrackId = id;
    selectedPlaylistId = null;
    playlistName = title;
    _announceMusicChange();
    notifyListeners();
  }

  /// Changing the music during a running or paused session switches the
  /// song right away. When idle it only remembers the choice for next time.
  void _announceMusicChange() {
    if (status == FocusStatus.idle) return;
    _runPlaylistId = selectedPlaylistId;
    _runTrackId = selectedTrackId;
    _bus.publish(FocusMusicChanged(
      playlistId: selectedPlaylistId,
      trackId: selectedTrackId,
      paused: status == FocusStatus.paused,
    ));
  }

  void start() {
    if (status != FocusStatus.idle) return;
    skipBreak(); // starting a session ends any break
    _startedAt = DateTime.now();
    _runPlaylistId = selectedPlaylistId;
    _runTrackId = selectedTrackId;
    remainingSeconds = selectedSeconds;
    status = FocusStatus.running;
    _bus.publish(
        FocusStarted(selectedSeconds, _runPlaylistId, trackId: _runTrackId));
    _startTicker();
    notifyListeners();
  }

  void pause() {
    if (status != FocusStatus.running) return;
    _timer?.cancel();
    status = FocusStatus.paused;
    _bus.publish(FocusPaused());
    notifyListeners();
  }

  void resume() {
    if (status != FocusStatus.paused) return;
    status = FocusStatus.running;
    _bus.publish(FocusResumed());
    _startTicker();
    notifyListeners();
  }

  void stop() {
    if (status == FocusStatus.idle) return;
    _timer?.cancel();
    final started = _startedAt!;
    final elapsed = selectedSeconds - remainingSeconds;
    status = FocusStatus.idle;
    remainingSeconds = selectedSeconds;
    _bus.publish(
        FocusCancelled(started, selectedSeconds, elapsed, _runPlaylistId));
    notifyListeners();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remainingSeconds--;
      if (remainingSeconds <= 0) {
        timer.cancel();
        final started = _startedAt!;
        status = FocusStatus.idle;
        remainingSeconds = selectedSeconds;
        _bus.publish(FocusCompleted(started, selectedSeconds, _runPlaylistId));
        if (autoBreak && breakSeconds > 0) _startBreak();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breakTimer?.cancel();
    _logoutSub?.cancel();
    _settingsSub?.cancel();
    super.dispose();
  }
}
