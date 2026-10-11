import 'package:sqflite/sqflite.dart';

import '../models/app_settings.dart';
import 'database_helper.dart';

/// Key/value storage for preferences. The table is created on first use with
/// IF NOT EXISTS, so no database version bump is needed.
class SettingsRepository {
  SettingsRepository(this._helper);
  final DatabaseHelper _helper;
  bool _ready = false;

  Future<Database> _db() async {
    final db = await _helper.database;
    if (!_ready) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )''');
      _ready = true;
    }
    return db;
  }

  Future<AppSettings> load() async {
    final db = await _db();
    final rows = await db.query('app_settings');
    final map = <String, String>{
      for (final r in rows) r['key'] as String: r['value'] as String,
    };
    return AppSettings.fromMap(map);
  }

  Future<void> save(AppSettings settings) async {
    final db = await _db();
    final batch = db.batch();
    settings.toMap().forEach((key, value) {
      batch.insert(
        'app_settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    await batch.commit(noResult: true);
  }
}
