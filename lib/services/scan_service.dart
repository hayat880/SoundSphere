import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../core/events/event_bus.dart';
import '../core/events/library_events.dart';
import '../core/events/scan_events.dart';
import '../models/track.dart';
import '../repositories/track_repository.dart';
import 'tag_service.dart';

enum ScanPermission { granted, denied, permanentlyDenied }

class ScanResult {
  const ScanResult(this.filesFound, this.added);
  final int filesFound;
  final int added;
}

/// Looks through the phone's music folders and adds every audio file to the
/// library, without copying it. Artist, album and title are worked out from
/// the file's embedded tags when it has them, otherwise from the file name and
/// folder names (for example Music/Artist/Album/01 - Song.mp3). Cover art is
/// saved from the tags too.
class ScanService {
  ScanService(this._tracks, this._bus, {TagService? tags}) : _tags = tags;
  final TrackRepository _tracks;
  final EventBus _bus;
  final TagService? _tags;

  static const Set<String> audioExtensions = {
    '.mp3', '.m4a', '.aac', '.wav', '.flac', '.ogg', '.opus',
  };

  /// Standard Android shared folders that normally hold music.
  static const List<String> defaultRoots = [
    '/storage/emulated/0/Music',
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Documents',
  ];

  /// Folders that hold sounds, not songs.
  static const Set<String> _skippedFolders = {
    'ringtones',
    'notifications',
    'alarms',
    'android',
  };

  /// Ignores tiny files such as UI sounds and clips.
  static const int _minBytes = 50 * 1024;

  static final p.Context _posix = p.posix; // Android paths always use "/"

  // ---------- permission ----------

  /// Android 13+ uses the audio permission; older versions use storage.
  Future<ScanPermission> requestPermission() async {
    if (await Permission.audio.isGranted || await Permission.storage.isGranted) {
      return ScanPermission.granted;
    }
    final audio = await Permission.audio.request();
    if (audio.isGranted) return ScanPermission.granted;
    final storage = await Permission.storage.request();
    if (storage.isGranted) return ScanPermission.granted;
    if (audio.isPermanentlyDenied || storage.isPermanentlyDenied) {
      return ScanPermission.permanentlyDenied;
    }
    return ScanPermission.denied;
  }

  Future<bool> openSystemSettings() => openAppSettings();

  // ---------- scanning ----------

  Future<ScanResult> scan({
    void Function(int found, String folder)? onProgress,
    List<String>? roots,
  }) async {
    var found = 0;
    var added = 0;
    var updated = 0;
    for (final root in roots ?? defaultRoots) {
      final dir = Directory(root);
      if (!await dir.exists()) continue;
      try {
        final entries = dir
            .list(recursive: true, followLinks: false)
            .handleError((Object _) {}, test: (e) => e is FileSystemException);
        await for (final entity in entries) {
          if (entity is! File) continue;
          final path = entity.path;
          if (!isAudioPath(path, root)) continue;
          try {
            if (await entity.length() < _minBytes) continue;
          } on FileSystemException {
            continue;
          }
          found++;
          final existing = await _tracks.byPath(path);
          if (existing == null) {
            final tags = await _tags?.read(path);
            final id =
                await _tracks.insert(trackFromPath(path, root).withTags(tags));
            if (id > 0) added++;
          } else if (existing.artworkPath == null && _tags != null) {
            // Songs scanned before tag reading existed get their tags now.
            final tags = await _tags.read(path);
            if (tags != null) {
              await _tracks.updateMeta(existing.withTags(tags));
              updated++;
            }
          }
          onProgress?.call(found, _posix.basename(_posix.dirname(path)));
          // Let the screen redraw during long scans.
          if (found % 20 == 0) await Future<void>.delayed(Duration.zero);
        }
      } on FileSystemException catch (e) {
        debugPrint('Scan skipped $root: $e');
      }
    }
    _bus.publish(ScanCompleted(filesFound: found, added: added));
    if (added > 0 || updated > 0) _bus.publish(LibraryUpdated(added + updated));
    return ScanResult(found, added);
  }

  // ---------- pure helpers (unit tested) ----------

  /// True for a real music file that is not hidden and not inside a sounds
  /// folder such as Ringtones or Alarms.
  static bool isAudioPath(String path, String root) {
    if (!audioExtensions.contains(_posix.extension(path).toLowerCase())) {
      return false;
    }
    if (_posix.basename(path).startsWith('.')) return false;
    final parts = _posix.split(_posix.relative(path, from: root));
    for (final folder in parts.take(parts.length - 1)) {
      if (folder.startsWith('.') ||
          _skippedFolders.contains(folder.toLowerCase())) {
        return false;
      }
    }
    return true;
  }

  /// Builds a [Track] from a file path.
  /// - "Artist - Title.mp3" gives the artist and title;
  /// - a leading track number ("01 - ", "02. ") is removed;
  /// - Root/Artist/Album/song.mp3 gives artist and album;
  /// - Root/Album/song.mp3 gives the album only.
  static Track trackFromPath(String path, String root) {
    final parts = _posix.split(_posix.relative(path, from: root));
    final folders = parts.sublist(0, parts.length - 1);
    final rawName = _posix.basenameWithoutExtension(path);

    final base = rawName
        .replaceFirst(RegExp(r'^\s*\d{1,3}\s*[-._)]\s*'), '')
        .replaceAll('_', ' ')
        .trim();

    var title = base;
    var artist = 'Unknown artist';
    var album = 'Unknown album';
    if (folders.length >= 2) {
      artist = folders[0];
      album = folders[1];
    } else if (folders.length == 1) {
      album = folders[0];
    }

    final dash = base.indexOf(' - ');
    if (dash > 0 && dash < base.length - 3) {
      artist = base.substring(0, dash).trim();
      title = base.substring(dash + 3).trim();
    }
    if (title.isEmpty) title = rawName;
    return Track(title: title, artist: artist, album: album, filePath: path);
  }
}
