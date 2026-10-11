import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/events/event_bus.dart';
import '../core/events/library_events.dart';
import '../models/track.dart';
import '../repositories/track_repository.dart';
import 'tag_service.dart';

/// Lets the user pick audio files, copies them into the app's own
/// folder and adds them to the database.
class ImportService {
  ImportService(this._tracks, this._bus, {TagService? tags}) : _tags = tags;
  final TrackRepository _tracks;
  final EventBus _bus;
  final TagService? _tags;

  Future<int> pickAndImport() async {
    // file_picker 12 and newer: pickFiles is static and returns a list.
    final files = await FilePicker.pickFiles(type: FileType.audio);
    if (files.isEmpty) return 0;

    final docs = await getApplicationDocumentsDirectory();
    final songsDir = Directory(p.join(docs.path, 'songs'));
    if (!await songsDir.exists()) await songsDir.create(recursive: true);

    var added = 0;
    for (final file in files) {
      final source = file.path;
      if (source == null) continue;
      final name = p.basename(source);
      final destination = p.join(songsDir.path, name);
      await File(source).copy(destination);
      final title = p.basenameWithoutExtension(name).replaceAll('_', ' ');
      final tags = await _tags?.read(destination);
      final id = await _tracks
          .insert(Track(title: title, filePath: destination).withTags(tags));
      if (id > 0) added++;
    }
    if (added > 0) _bus.publish(LibraryUpdated(added));
    return added;
  }
}
