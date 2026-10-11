import 'track.dart';

/// One song found in the online catalog (Audius, free and legal to stream).
class OnlineTrack {
  const OnlineTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.durationSeconds,
    required this.streamUrl,
    this.artworkUrl,
    this.downloadable = false,
    this.releasedAt,
  });

  final String id;
  final String title;
  final String artist;
  final int durationSeconds;
  final String streamUrl;
  final String? artworkUrl;

  /// True only when the artist allows downloading this song.
  final bool downloadable;

  /// When the song was released or uploaded, if the catalog says.
  final DateTime? releasedAt;

  /// The library entry for this song. Its "file path" is the stream address.
  Track toTrack() => Track(
        title: title,
        artist: artist,
        album: 'Online',
        filePath: streamUrl,
        durationMs: durationSeconds * 1000,
        artworkPath: artworkUrl,
      );
}
