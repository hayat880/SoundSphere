import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user_profile.dart';
import 'database_helper.dart';

class AccountException implements Exception {
  final String message;
  AccountException(this.message);
  @override
  String toString() => message;
}

/// Local-only accounts. Passwords are salted and hashed (SHA-256), never
/// stored in plain text. Tables are created lazily with IF NOT EXISTS so no
/// database version bump or migration is needed.
class AccountRepository {
  AccountRepository(this._helper);
  final DatabaseHelper _helper;
  bool _ready = false;

  // ASSUMPTION: DatabaseHelper exposes `Future<Database> get database`.
  Future<Database> _db() async {
    final db = await _helper.database;
    if (!_ready) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS local_account (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          salt TEXT NOT NULL,
          password_hash TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS account_session (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )''');
      _ready = true;
    }
    return db;
  }

  String _salt() {
    final r = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  Future<UserProfile> create(
      String name, String email, String password) async {
    final db = await _db();
    final mail = email.trim().toLowerCase();
    final exists =
        await db.query('local_account', where: 'email = ?', whereArgs: [mail]);
    if (exists.isNotEmpty) {
      throw AccountException('An account with this email already exists.');
    }
    final salt = _salt();
    final id = await db.insert('local_account', {
      'name': name.trim(),
      'email': mail,
      'salt': salt,
      'password_hash': _hash(salt, password),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    return (await byId(id))!;
  }

  /// Signs in a person who proved their email with Google. The first time, a
  /// local account is created with a random password that nobody knows, so
  /// the account can only be opened through Google.
  Future<UserProfile> findOrCreateExternal(String name, String email) async {
    final db = await _db();
    final mail = email.trim().toLowerCase();
    final rows =
        await db.query('local_account', where: 'email = ?', whereArgs: [mail]);
    if (rows.isNotEmpty) return UserProfile.fromMap(rows.first);
    return create(name.trim().isEmpty ? mail.split('@').first : name, mail,
        _salt() + _salt());
  }

  Future<UserProfile> verify(String email, String password) async {
    final db = await _db();
    final rows = await db.query('local_account',
        where: 'email = ?', whereArgs: [email.trim().toLowerCase()]);
    if (rows.isEmpty ||
        rows.first['password_hash'] !=
            _hash(rows.first['salt'] as String, password)) {
      // Same message for both cases so emails cannot be probed.
      throw AccountException('Incorrect email or password.');
    }
    return UserProfile.fromMap(rows.first);
  }

  Future<UserProfile?> byId(int id) async {
    final db = await _db();
    final rows =
        await db.query('local_account', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : UserProfile.fromMap(rows.first);
  }

  Future<void> rename(int id, String name) async {
    final db = await _db();
    await db.update('local_account', {'name': name.trim()},
        where: 'id = ?', whereArgs: [id]);
  }

  // ---- remembered session: "user:<id>", "guest" or nothing ----
  Future<void> saveSession(String? value) async {
    final db = await _db();
    if (value == null) {
      await db.delete('account_session', where: 'key = ?', whereArgs: ['current']);
    } else {
      await db.insert('account_session', {'key': 'current', 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<String?> loadSession() async {
    final db = await _db();
    final rows = await db
        .query('account_session', where: 'key = ?', whereArgs: ['current']);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }
}
