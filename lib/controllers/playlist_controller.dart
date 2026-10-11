import 'package:flutter/foundation.dart';

import '../models/playlist.dart';
import '../models/track.dart';
import '../repositories/playlist_repository.dart';

class PlaylistController extends ChangeNotifier {
  PlaylistController(this._repo);
  final PlaylistRepository _repo;

  List<Playlist> playlists = [];
  final Map<int, List<Track>> _tracks = {};

  Future<void> load() async {
    playlists = await _repo.all();
    notifyListeners();
  }

  Future<int> create(String name) async {
    final id = await _repo.create(name);
    await load();
    return id;
  }

  Future<void> rename(int id, String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    await _repo.rename(id, clean);
    await load();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    _tracks.remove(id);
    await load();
  }

  List<Track> tracksFor(int playlistId) => _tracks[playlistId] ?? const [];

  Future<void> loadTracks(int playlistId) async {
    _tracks[playlistId] = await _repo.tracksOf(playlistId);
    notifyListeners();
  }

  Future<void> addTrack(int playlistId, int trackId) async {
    await _repo.addTrack(playlistId, trackId);
    await loadTracks(playlistId);
    await load();
  }

  Future<void> removeTrack(int playlistId, int trackId) async {
    await _repo.removeTrack(playlistId, trackId);
    await loadTracks(playlistId);
    await load();
  }
}
