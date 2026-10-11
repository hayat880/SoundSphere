import '../models/focus_session.dart';
import 'database_helper.dart';

class SessionRepository {
  SessionRepository(this._db);
  final DatabaseHelper _db;

  /// Saves a session. Returns false if this session was already saved
  /// (same start time), so handlers can never create duplicates.
  Future<bool> save(FocusSession session) async {
    final db = await _db.database;
    final existing = await db.query(
      'focus_sessions',
      where: 'started_at = ?',
      whereArgs: [session.startedAt.toIso8601String()],
      limit: 1,
    );
    if (existing.isNotEmpty) return false;
    await db.insert('focus_sessions', session.toMap());
    return true;
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('focus_sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clear() async {
    final db = await _db.database;
    await db.delete('focus_sessions');
  }

  Future<List<FocusSession>> all() async {
    final db = await _db.database;
    final rows = await db.query('focus_sessions', orderBy: 'started_at DESC');
    return rows.map(FocusSession.fromMap).toList();
  }
}
