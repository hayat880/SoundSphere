import 'app_event.dart';

/// A scan of the phone's music folders finished.
class ScanCompleted extends AppEvent {
  ScanCompleted({required this.filesFound, required this.added});
  final int filesFound;
  final int added;
}
