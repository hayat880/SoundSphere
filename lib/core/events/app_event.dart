/// Base class for every event in the app. Events are immutable facts
/// describing something that already happened.
abstract class AppEvent {
  final DateTime timestamp = DateTime.now();
}
