/// Special id for the built-in "Liked Songs" list. It is never stored in
/// the database; it is built from the songs marked as favorite.
const int kLikedPlaylistId = -1;

class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.createdAt,
    this.trackCount = 0,
  });

  final int id;
  final String name;
  final DateTime createdAt;
  final int trackCount;

  factory Playlist.fromMap(Map<String, Object?> m) => Playlist(
        id: m['id'] as int,
        name: m['name'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
        trackCount: (m['track_count'] as int?) ?? 0,
      );
}
