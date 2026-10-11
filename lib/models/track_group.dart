import 'track.dart';

enum GroupKind { album, artist }

/// Songs that share an album or an artist.
class TrackGroup {
  const TrackGroup(this.name, this.tracks);
  final String name;
  final List<Track> tracks;
  int get count => tracks.length;

  /// The first cover picture found among the songs, if any.
  String? get artworkPath {
    for (final t in tracks) {
      if (t.artworkPath != null) return t.artworkPath;
    }
    return null;
  }
}

/// The newest songs first (higher ids were added later).
List<Track> recentlyAdded(List<Track> tracks, {int limit = 12}) {
  final sorted = List<Track>.of(tracks)
    ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
  return sorted.take(limit).toList();
}

/// Artists with the most songs, ignoring the "Unknown" placeholders.
List<TrackGroup> topArtists(List<TrackGroup> artists, {int limit = 10}) {
  final known = artists
      .where((g) => g.name != 'Unknown' && g.name != 'Unknown artist')
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));
  return known.take(limit).toList();
}

/// Groups [tracks] by the key [keyOf] returns (album or artist), sorted by
/// name. An empty key becomes "Unknown".
List<TrackGroup> groupTracks(
  List<Track> tracks,
  String Function(Track) keyOf,
) {
  final map = <String, List<Track>>{};
  for (final t in tracks) {
    final raw = keyOf(t).trim();
    map.putIfAbsent(raw.isEmpty ? 'Unknown' : raw, () => <Track>[]).add(t);
  }
  final groups = map.entries.map((e) => TrackGroup(e.key, e.value)).toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return groups;
}
