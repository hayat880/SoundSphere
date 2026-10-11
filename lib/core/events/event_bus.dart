import 'dart:async';

import 'app_event.dart';

/// One broadcast stream that delivers typed events to any handler
/// that subscribes. The publisher never knows who is listening.
class EventBus {
  final StreamController<AppEvent> _controller =
      StreamController<AppEvent>.broadcast();

  void publish(AppEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  Stream<T> on<T extends AppEvent>() =>
      _controller.stream.where((e) => e is T).cast<T>();

  void dispose() => _controller.close();
}
