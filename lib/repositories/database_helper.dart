import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Opens the SQLite database once and creates all tables.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'soundsphere.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tracks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            artist TEXT,
            album TEXT,
            file_path TEXT NOT NULL UNIQUE,
            duration_ms INTEGER,
            artwork_path TEXT,
            is_favorite INTEGER NOT NULL DEFAULT 0
          )''');
        await db.execute('''
          CREATE TABLE playlists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at TEXT NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE playlist_tracks (
            playlist_id INTEGER NOT NULL,
            track_id INTEGER NOT NULL,
            position INTEGER NOT NULL,
            PRIMARY KEY (playlist_id, track_id),
            FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
            FOREIGN KEY (track_id) REFERENCES tracks(id) ON DELETE CASCADE
          )''');
        await db.execute('''
          CREATE TABLE listening_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            track_id INTEGER NOT NULL,
            played_at TEXT NOT NULL,
            progress_seconds INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (track_id) REFERENCES tracks(id) ON DELETE CASCADE
          )''');
        await db.execute('''
          CREATE TABLE focus_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            started_at TEXT NOT NULL,
            planned_minutes INTEGER NOT NULL,
            actual_seconds INTEGER NOT NULL,
            completed INTEGER NOT NULL DEFAULT 0,
            playlist_id INTEGER,
            FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE SET NULL
          )''');
        await db.execute('''
          CREATE TABLE ambient_mixes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            volumes_json TEXT NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE profile (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL
          )''');
      },
    );
  }
}
