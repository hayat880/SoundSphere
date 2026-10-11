import 'app_event.dart';

/// A break began (automatically after a focus session).
class BreakStarted extends AppEvent {
  BreakStarted(this.breakSeconds);
  final int breakSeconds;
}

/// The break timer reached zero.
class BreakCompleted extends AppEvent {
  BreakCompleted(this.breakSeconds);
  final int breakSeconds;
}

/// The user ended the break early (Skip break, or started a new session).
class BreakSkipped extends AppEvent {}
