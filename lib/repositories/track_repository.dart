import 'package:sqflite/sqflite.dart';

import '../models/track.dart';
import 'database_helper.dart';

class TrackRepository {
  TrackRepository(this._db);
  final DatabaseHelper _db;

  Future<List<Track>> all() async {
    final db = await _db.database;
    final rows = await db.query('tracks', orderBy: 'title COLLATE NOCASE');
    return rows.map(Track.fromMap).toList();
  }

  /// Returns the new row id, or 0 if the file was already in the library.
  Future<int> insert(Track track) async {
    final db = await _db.database;
    return db.insert(
      'tracks',
      track.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<Track?> byPath(String path) async {
    final db = await _db.database;
    final rows =
        await db.query('tracks', where: 'file_path = ?', whereArgs: [path]);
    return rows.isEmpty ? null : Track.fromMap(rows.first);
  }

  /// Saves tag information read from the file itself.
  Future<void> updateMeta(Track track) async {
    final id = track.id;
    if (id == null) return;
    final db = await _db.database;
    await db.update(
      'tracks',
      {
        'title': track.title,
        'artist': track.artist,
        'album': track.album,
        'duration_ms': track.durationMs,
        'artwork_path': track.artworkPath,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Points a library song at a downloaded file. The row (and so its
  /// playlists, favorite flag and history) stays the same.
  Future<void> relink(int id, String filePath, String? artworkPath) async {
    final db = await _db.database;
    await db.update(
      'tracks',
      {
        'file_path': filePath,
        if (artworkPath != null) 'artwork_path': artworkPath,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setFavorite(int id, bool isFavorite) async {
    final db = await _db.database;
    await db.update(
      'tracks',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('tracks', where: 'id = ?', whereArgs: [id]);
  }
}
