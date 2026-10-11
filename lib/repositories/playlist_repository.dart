import 'package:sqflite/sqflite.dart';

import '../models/playlist.dart';
import '../models/track.dart';
import 'database_helper.dart';

class PlaylistRepository {
  PlaylistRepository(this._db);
  final DatabaseHelper _db;

  Future<List<Playlist>> all() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT p.*,
        (SELECT COUNT(*) FROM playlist_tracks pt WHERE pt.playlist_id = p.id)
          AS track_count
      FROM playlists p
      ORDER BY p.created_at DESC''');
    return rows.map(Playlist.fromMap).toList();
  }

  Future<int> create(String name) async {
    final db = await _db.database;
    return db.insert('playlists', {
      'name': name.trim(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> rename(int id, String name) async {
    final db = await _db.database;
    await db.update('playlists', {'name': name.trim()},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addTrack(int playlistId, int trackId) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT COALESCE(MAX(position), -1) + 1 AS next '
      'FROM playlist_tracks WHERE playlist_id = ?',
      [playlistId],
    );
    final next = (rows.first['next'] as int?) ?? 0;
    await db.insert(
      'playlist_tracks',
      {'playlist_id': playlistId, 'track_id': trackId, 'position': next},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeTrack(int playlistId, int trackId) async {
    final db = await _db.database;
    await db.delete('playlist_tracks',
        where: 'playlist_id = ? AND track_id = ?',
        whereArgs: [playlistId, trackId]);
  }

  Future<List<Track>> tracksOf(int playlistId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT t.* FROM tracks t
      JOIN playlist_tracks pt ON pt.track_id = t.id
      WHERE pt.playlist_id = ?
      ORDER BY pt.position''', [playlistId]);
    return rows.map(Track.fromMap).toList();
  }
}
