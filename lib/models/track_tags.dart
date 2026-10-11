/// What could be read from the tags inside one audio file.
class TrackTags {
  const TrackTags({
    this.title,
    this.artist,
    this.album,
    this.durationMs = 0,
    this.artworkPath,
  });
  final String? title;
  final String? artist;
  final String? album;
  final int durationMs;
  final String? artworkPath;

  bool get isEmpty =>
      title == null &&
      artist == null &&
      album == null &&
      artworkPath == null &&
      durationMs == 0;
}
