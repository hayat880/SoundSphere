import 'app_event.dart';

/// Songs were added or changed in the database.
class LibraryUpdated extends AppEvent {
  LibraryUpdated(this.count);
  final int count;
}

/// A listening-history row was saved.
class HistoryUpdated extends AppEvent {}
