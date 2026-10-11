import '../../models/track.dart';
import 'app_event.dart';

/// The user chose a song (or asked to shuffle a list).
class TrackSelected extends AppEvent {
  TrackSelected(this.queue, this.index, {this.shuffle = false});
  final List<Track> queue;
  final int index;
  final bool shuffle;
}

/// The audio engine started, paused or changed track.
class PlaybackStateChanged extends AppEvent {
  PlaybackStateChanged(this.isPlaying, this.track);
  final bool isPlaying;
  final Track? track;
}

/// The queue order, shuffle mode or repeat mode changed.
class QueueChanged extends AppEvent {}

/// A song played to the end.
class TrackPlaybackCompleted extends AppEvent {
  TrackPlaybackCompleted(this.track);
  final Track track;
}

/// The user hearted or un-hearted a song.
class FavoriteChanged extends AppEvent {
  FavoriteChanged(this.trackId, this.isFavorite);
  final int trackId;
  final bool isFavorite;
}

/// Something could not be played. Shown to the user as a message.
class PlaybackFailed extends AppEvent {
  PlaybackFailed(this.message);
  final String message;
}
