import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/track_tags.dart';

/// Reads embedded tags (ID3, MP4, FLAC, Vorbis) and cover art. Cover images
/// are saved once under the app's "art" folder and shared by songs that have
/// the same picture. Never throws: a file that cannot be read gives null.
class TagService {
  Directory? _artDir;

  Future<TrackTags?> read(String path) async {
    try {
      final meta = readMetadata(File(path), getImage: true);
      String? clean(String? v) {
        final t = v?.trim();
        return (t == null || t.isEmpty) ? null : t;
      }

      String? artwork;
      final pictures = meta.pictures;
      if (pictures.isNotEmpty && pictures.first.bytes.isNotEmpty) {
        artwork = await _saveArt(pictures.first.bytes);
      }
      final tags = TrackTags(
        title: clean(meta.title),
        artist: clean(meta.artist),
        album: clean(meta.album),
        durationMs: meta.duration?.inMilliseconds ?? 0,
        artworkPath: artwork,
      );
      return tags.isEmpty ? null : tags;
    } catch (e) {
      debugPrint('Could not read tags of $path: $e');
      return null;
    }
  }

  Future<String> _saveArt(List<int> bytes) async {
    var dir = _artDir;
    if (dir == null) {
      final docs = await getApplicationDocumentsDirectory();
      dir = Directory(p.join(docs.path, 'art'));
      if (!await dir.exists()) await dir.create(recursive: true);
      _artDir = dir;
    }
    final name = sha1.convert(bytes).toString();
    final file = File(p.join(dir.path, '$name.img'));
    if (!await file.exists()) await file.writeAsBytes(bytes);
    return file.path;
  }
}
