import 'track_tags.dart';

class Track {
  const Track({
    this.id,
    required this.title,
    this.artist = 'Unknown artist',
    this.album = 'Unknown album',
    required this.filePath,
    this.durationMs = 0,
    this.artworkPath,
    this.isFavorite = false,
  });

  final int? id;
  final String title;
  final String artist;
  final String album;
  final String filePath;
  final int durationMs;
  final String? artworkPath;
  final bool isFavorite;

  /// True for songs streamed from the online catalog (the path is a web address).
  bool get isOnline => filePath.startsWith('http://') || filePath.startsWith('https://');

  Track copyWith({
    String? title,
    String? artist,
    String? album,
    int? durationMs,
    String? artworkPath,
  }) =>
      Track(
        id: id,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        album: album ?? this.album,
        filePath: filePath,
        durationMs: durationMs ?? this.durationMs,
        artworkPath: artworkPath ?? this.artworkPath,
        isFavorite: isFavorite,
      );

  /// Prefers what the file's own tags say over names guessed from the path.
  Track withTags(TrackTags? tags) {
    if (tags == null) return this;
    return copyWith(
      title: tags.title,
      artist: tags.artist,
      album: tags.album,
      durationMs: tags.durationMs > 0 ? tags.durationMs : null,
      artworkPath: tags.artworkPath,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'file_path': filePath,
        'duration_ms': durationMs,
        'artwork_path': artworkPath,
        'is_favorite': isFavorite ? 1 : 0,
      };

  factory Track.fromMap(Map<String, Object?> m) => Track(
        id: m['id'] as int?,
        title: m['title'] as String,
        artist: (m['artist'] as String?) ?? 'Unknown artist',
        album: (m['album'] as String?) ?? 'Unknown album',
        filePath: m['file_path'] as String,
        durationMs: (m['duration_ms'] as int?) ?? 0,
        artworkPath: m['artwork_path'] as String?,
        isFavorite: ((m['is_favorite'] as int?) ?? 0) == 1,
      );
}
