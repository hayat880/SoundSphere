import '../../models/focus_session.dart';
import 'app_event.dart';

class FocusStarted extends AppEvent {
  FocusStarted(this.plannedSeconds, this.playlistId, {this.trackId});
  final int plannedSeconds;

  /// One chosen song to play (and repeat) during the session. When set,
  /// [playlistId] is ignored.
  final int? trackId;

  /// null = all songs, kLikedPlaylistId = liked songs, otherwise a playlist id.
  final int? playlistId;
}

class FocusPaused extends AppEvent {}

class FocusResumed extends AppEvent {}

class FocusCompleted extends AppEvent {
  FocusCompleted(this.startedAt, this.plannedSeconds, this.playlistId);
  final DateTime startedAt;
  final int plannedSeconds;
  final int? playlistId;
}

class FocusCancelled extends AppEvent {
  FocusCancelled(
      this.startedAt, this.plannedSeconds, this.elapsedSeconds, this.playlistId);
  final DateTime startedAt;
  final int plannedSeconds;
  final int elapsedSeconds;
  final int? playlistId;
}

/// A focus session was written to the database.
class SessionSaved extends AppEvent {
  SessionSaved(this.session);
  final FocusSession session;
}

/// All saved focus sessions were deleted (Settings → Clear focus history).
class FocusHistoryCleared extends AppEvent {}

/// The music choice was changed while a session is running or paused.
class FocusMusicChanged extends AppEvent {
  FocusMusicChanged({this.playlistId, this.trackId, this.paused = false});

  /// null = all songs, kLikedPlaylistId = liked songs, otherwise a playlist id.
  final int? playlistId;

  /// When set, this one song plays (and repeats). [playlistId] is ignored.
  final int? trackId;

  /// True when the session is paused: the new music loads but stays paused.
  final bool paused;
}
