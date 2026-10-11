import '../models/track.dart';
import 'database_helper.dart';

class HistoryRepository {
  HistoryRepository(this._db);
  final DatabaseHelper _db;

  Future<void> add(int trackId, int progressSeconds) async {
    final db = await _db.database;
    await db.insert('listening_history', {
      'track_id': trackId,
      'played_at': DateTime.now().toIso8601String(),
      'progress_seconds': progressSeconds,
    });
  }

  Future<void> clear() async {
    final db = await _db.database;
    await db.delete('listening_history');
  }

  /// Songs played to the end most often, best first.
  Future<List<Track>> mostPlayedTracks({int limit = 10}) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT t.* FROM tracks t
      JOIN listening_history h ON h.track_id = t.id
      GROUP BY t.id
      ORDER BY COUNT(*) DESC, MAX(h.played_at) DESC
      LIMIT ?''', [limit]);
    return rows.map(Track.fromMap).toList();
  }

  Future<List<Track>> recentTracks({int limit = 10}) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT t.* FROM tracks t
      JOIN listening_history h ON h.track_id = t.id
      GROUP BY t.id
      ORDER BY MAX(h.played_at) DESC
      LIMIT ?''', [limit]);
    return rows.map(Track.fromMap).toList();
  }
}
