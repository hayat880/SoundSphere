import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/online_track.dart';
import 'online_service.dart';

/// Where a downloaded song and its cover ended up.
class DownloadedSong {
  const DownloadedSong(this.path, this.artworkPath);
  final String path;
  final String? artworkPath;
}

/// Saves online songs into the app's own folder so they play offline.
class DownloadService {
  DownloadService(this._online);
  final OnlineService _online;

  Directory? _dir;

  Future<Directory> _songsDir() async {
    var dir = _dir;
    if (dir == null) {
      final docs = await getApplicationDocumentsDirectory();
      dir = Directory(p.join(docs.path, 'songs', 'online'));
      if (!await dir.exists()) await dir.create(recursive: true);
      _dir = dir;
    }
    return dir;
  }

  /// Letters, digits and dashes only, so the name is safe on any phone.
  static String safeName(OnlineTrack song) {
    final title = song.title
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final short = title.length > 40 ? title.substring(0, 40) : title;
    return short.isEmpty ? song.id : '$short-${song.id}';
  }

  Future<String> localPathFor(OnlineTrack song) async =>
      p.join((await _songsDir()).path, '${safeName(song)}.mp3');

  Future<bool> isDownloaded(OnlineTrack song) async =>
      File(await localPathFor(song)).exists();

  Future<DownloadedSong> download(OnlineTrack song) async {
    final path = await localPathFor(song);
    await _online.download(song, File(path));
    return DownloadedSong(path, await _saveCover(song, path));
  }

  /// The cover is a nice extra: when it cannot be saved the song still works.
  Future<String?> _saveCover(OnlineTrack song, String songPath) async {
    final url = song.artworkUrl;
    if (url == null) return null;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final file = File(p.setExtension(songPath, '.jpg'));
      final sink = file.openWrite();
      try {
        await sink.addStream(response);
      } finally {
        await sink.close();
      }
      return await file.length() > 0 ? file.path : null;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
