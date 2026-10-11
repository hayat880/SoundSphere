import 'package:flutter/foundation.dart';

import '../core/events/event_bus.dart';
import '../core/events/library_events.dart';
import '../models/online_track.dart';
import '../models/track.dart';
import '../repositories/track_repository.dart';
import '../services/download_service.dart';
import '../services/online_service.dart';

/// The ready-made lists on the Find music screen.
enum OnlineFeed {
  trending('Trending'),
  latest('Latest'),
  month('This month'),
  year('This year'),
  allTime('Old & classics');

  const OnlineFeed(this.label);
  final String label;
}

/// Genres the catalog understands (the spelling matters).
const List<String> onlineGenres = [
  'Electronic',
  'Hip-Hop/Rap',
  'Pop',
  'Rock',
  'Lo-Fi',
  'Ambient',
  'Jazz',
  'Folk',
  'Classical',
  'R&B/Soul',
  'Devotional',
  'World',
  'Latin',
  'Reggae',
];

/// Search the online catalog and bring songs into the library.
class OnlineController extends ChangeNotifier {
  OnlineController(this._bus, this._tracks, this._service,
      {DownloadService? downloads})
      : _downloads = downloads;
  final EventBus _bus;
  final TrackRepository _tracks;
  final OnlineService _service;
  final DownloadService? _downloads;

  /// Ids of songs being downloaded right now, and songs already saved.
  final Set<String> downloading = {};
  Set<String> downloaded = {};

  List<OnlineTrack> results = [];
  bool loading = false;
  String? error;
  String query = '';
  OnlineFeed feed = OnlineFeed.trending;
  String? genre;

  /// When true (the default) only songs the artist lets people download show.
  bool onlyDownloadable = true;
  bool _loadedOnce = false;
  int _request = 0; // ignores answers that arrive after a newer search

  /// Shows trending songs the first time the screen opens.
  Future<void> loadTrendingOnce() async {
    if (_loadedOnce) return;
    _loadedOnce = true;
    await _loadFeed();
  }

  Future<void> _loadFeed() => _run(() {
        switch (feed) {
          case OnlineFeed.latest:
            return _service.latest(
                genre: genre, onlyDownloadable: onlyDownloadable);
          case OnlineFeed.trending:
            return _service.trending(
                time: 'week', genre: genre, onlyDownloadable: onlyDownloadable);
          case OnlineFeed.month:
            return _service.trending(
                time: 'month', genre: genre, onlyDownloadable: onlyDownloadable);
          case OnlineFeed.year:
            return _service.trending(
                time: 'year', genre: genre, onlyDownloadable: onlyDownloadable);
          case OnlineFeed.allTime:
            return _service.trending(
                time: 'allTime',
                genre: genre,
                onlyDownloadable: onlyDownloadable);
        }
      });

  Future<void> setFeed(OnlineFeed value) {
    feed = value;
    query = '';
    return _loadFeed();
  }

  /// Pass null for "all genres".
  Future<void> setGenre(String? value) {
    genre = value;
    return query.isEmpty ? _loadFeed() : search(query);
  }

  Future<void> setOnlyDownloadable(bool value) {
    onlyDownloadable = value;
    return query.isEmpty ? _loadFeed() : search(query);
  }

  Future<void> search(String text) async {
    query = text.trim();
    if (query.isEmpty) {
      await _loadFeed();
    } else {
      await _run(() => _service.search(query,
          genre: genre, onlyDownloadable: onlyDownloadable));
    }
  }

  Future<void> _run(Future<List<OnlineTrack>> Function() action) async {
    final mine = ++_request;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final found = await action();
      final saved = <String>{};
      final dl = _downloads;
      if (dl != null) {
        for (final s in found) {
          if (await dl.isDownloaded(s)) saved.add(s.id);
        }
      }
      if (mine != _request) return;
      results = found;
      downloaded = saved;
    } on OnlineException catch (e) {
      if (mine != _request) return;
      results = [];
      error = e.message;
    } catch (_) {
      if (mine != _request) return;
      results = [];
      error = 'Something went wrong. Please try again.';
    } finally {
      if (mine == _request) {
        loading = false;
        notifyListeners();
      }
    }
  }

  /// Adds the song to the library (once) and returns the saved track, which
  /// has an id so it can go into playlists, favorites and history.
  Future<Track?> addToLibrary(OnlineTrack song) async {
    var wanted = song.toTrack();
    // Already downloaded: use the file on the phone instead of the stream.
    final dl = _downloads;
    if (dl != null && await dl.isDownloaded(song)) {
      wanted = Track(
        title: wanted.title,
        artist: wanted.artist,
        album: wanted.album,
        filePath: await dl.localPathFor(song),
        durationMs: wanted.durationMs,
        artworkPath: wanted.artworkPath,
      );
    }
    final added = await _tracks.insert(wanted);
    final saved = await _tracks.byPath(wanted.filePath);
    if (added > 0) _bus.publish(LibraryUpdated(1));
    return saved;
  }

  /// Downloads the song so it plays offline. Returns a message to show.
  Future<String> download(OnlineTrack song) async {
    final dl = _downloads;
    if (dl == null) return 'Downloads are not available in this build.';
    if (!song.downloadable) {
      return 'The artist has not allowed downloading this song.';
    }
    if (downloading.contains(song.id)) return 'Already downloading.';
    downloading.add(song.id);
    notifyListeners();
    try {
      final saved = await addToLibrary(song);
      if (!await dl.isDownloaded(song)) {
        final file = await dl.download(song);
        final id = saved?.id;
        if (id != null && await _tracks.byPath(file.path) == null) {
          await _tracks.relink(id, file.path, file.artworkPath);
        }
      }
      downloaded = {...downloaded, song.id};
      _bus.publish(LibraryUpdated(1));
      return 'Downloaded "${song.title}". It now plays offline.';
    } on OnlineException catch (e) {
      return e.message;
    } catch (_) {
      return 'The download failed. Please try again.';
    } finally {
      downloading.remove(song.id);
      notifyListeners();
    }
  }
}
