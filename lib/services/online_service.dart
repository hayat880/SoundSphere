import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/online_track.dart';

class OnlineException implements Exception {
  OnlineException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Searches the Audius catalog. Audius needs no account or key and lets apps
/// stream its songs. Uses only dart:io, so no extra package is needed.
class OnlineService {
  static const String host = 'https://api.audius.co';
  static const String appName = 'SoundSphere';

  /// Songs matching [query]. With [onlyDownloadable] only songs the artist
  /// lets people save are returned.
  Future<List<OnlineTrack>> search(String query,
          {String? genre, bool onlyDownloadable = false, int limit = 25}) =>
      _feed('/v1/tracks/search', {
        'query': query.trim(),
        if (genre != null) 'genre': genre,
        if (onlyDownloadable) 'only_downloadable': 'true',
      }, onlyDownloadable: onlyDownloadable, limit: limit);

  /// The most played songs. [time] is week, month, year or allTime, so
  /// "allTime" gives the old classics and "week" what is hot right now.
  Future<List<OnlineTrack>> trending(
          {String time = 'week',
          String? genre,
          bool onlyDownloadable = false,
          int limit = 25}) =>
      _feed('/v1/tracks/trending', {
        'time': time,
        if (genre != null) 'genre': genre,
      }, onlyDownloadable: onlyDownloadable, limit: limit);

  /// The newest songs that are getting played: this week's popular songs,
  /// sorted from newest to oldest.
  Future<List<OnlineTrack>> latest(
          {String? genre, bool onlyDownloadable = false, int limit = 25}) =>
      _feed('/v1/tracks/trending', {
        'time': 'week',
        if (genre != null) 'genre': genre,
      }, onlyDownloadable: onlyDownloadable, limit: limit, newestFirst: true);

  /// Asks for a bigger pool when we filter or sort, so that [limit] songs
  /// are still left afterwards.
  Future<List<OnlineTrack>> _feed(String path, Map<String, String> query,
      {required bool onlyDownloadable,
      required int limit,
      bool newestFirst = false}) async {
    final pool = onlyDownloadable || newestFirst ? 100 : limit;
    final songs = await _get(path, {...query, 'limit': '$pool'},
        onlyDownloadable: onlyDownloadable);
    if (newestFirst) sortNewest(songs);
    return songs.length > limit ? songs.sublist(0, limit) : songs;
  }

  /// Newest first. Songs without a date go last.
  static void sortNewest(List<OnlineTrack> songs) {
    songs.sort((a, b) {
      final x = a.releasedAt, y = b.releasedAt;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return y.compareTo(x);
    });
  }

  Future<List<OnlineTrack>> _get(String path, Map<String, String> query,
      {bool onlyDownloadable = false}) async {
    final uri = Uri.parse('$host$path')
        .replace(queryParameters: {...query, 'app_name': appName});
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw OnlineException(
            'The music catalog is not answering (${response.statusCode}). Try again later.');
      }
      final body = await response.transform(utf8.decoder).join();
      return parseTracks(body, onlyDownloadable: onlyDownloadable);
    } on SocketException {
      throw OnlineException('No internet connection.');
    } on TimeoutException {
      throw OnlineException('The music catalog took too long. Try again.');
    } on HandshakeException {
      throw OnlineException('Could not make a secure connection.');
    } finally {
      client.close(force: true);
    }
  }

  Uri downloadUri(OnlineTrack song) => Uri.parse(
      '$host/v1/tracks/${song.id}/download?app_name=$appName');

  /// Saves the song's audio file to [dest]. Only call it for songs whose
  /// artist allows downloads. Writes to a temporary file first, so a failed
  /// download never leaves a broken song behind.
  Future<void> download(OnlineTrack song, File dest) async {
    final part = File('${dest.path}.part');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      var response = await _open(client, downloadUri(song));
      // Some servers answer with a small JSON note that holds the real link.
      if (response.headers.contentType?.mimeType == 'application/json') {
        final body = await response.transform(utf8.decoder).join();
        final link = _linkIn(body);
        if (link == null) {
          throw OnlineException(
              'The artist has not allowed downloading this song.');
        }
        response = await _open(client, Uri.parse(link));
      }
      final sink = part.openWrite();
      try {
        await sink.addStream(response);
      } finally {
        await sink.close();
      }
      if (await part.length() < 10 * 1024) {
        throw OnlineException('The download did not finish. Try again.');
      }
      if (await dest.exists()) await dest.delete();
      await part.rename(dest.path);
    } on SocketException {
      throw OnlineException('No internet connection.');
    } on TimeoutException {
      throw OnlineException('The download took too long. Try again.');
    } on HttpException {
      throw OnlineException('The download was interrupted. Try again.');
    } finally {
      client.close(force: true);
      if (await part.exists()) {
        try {
          await part.delete();
        } on FileSystemException {
          // Nothing more to clean up.
        }
      }
    }
  }

  Future<HttpClientResponse> _open(HttpClient client, Uri uri) async {
    final request = await client.getUrl(uri);
    final response = await request.close().timeout(const Duration(seconds: 30));
    if (response.statusCode == 403 || response.statusCode == 404) {
      throw OnlineException('The artist has not allowed downloading this song.');
    }
    if (response.statusCode != 200) {
      throw OnlineException('Download failed (${response.statusCode}).');
    }
    return response;
  }

  static String? _linkIn(String body) {
    try {
      final json = jsonDecode(body);
      final data = json is Map ? json['data'] : null;
      if (data is String && data.startsWith('http')) return data;
      if (data is Map && data['url'] is String) return data['url'] as String;
    } on FormatException {
      return null;
    }
    return null;
  }

  /// Turns the catalog's JSON into songs. Songs that cannot be streamed or
  /// are missing basic fields are skipped. Pure, so it is unit tested.
  static List<OnlineTrack> parseTracks(String body,
      {bool onlyDownloadable = false}) {
    final Object? json;
    try {
      json = jsonDecode(body);
    } on FormatException {
      throw OnlineException('The music catalog sent something unexpected.');
    }
    final data = json is Map ? json['data'] : null;
    if (data is! List) return const [];
    final result = <OnlineTrack>[];
    for (final item in data) {
      if (item is! Map) continue;
      final id = item['id'];
      final title = item['title'];
      if (id is! String || title is! String || title.trim().isEmpty) continue;
      if (item['is_streamable'] == false) continue;
      final user = item['user'];
      final artist = user is Map && user['name'] is String
          ? (user['name'] as String).trim()
          : '';
      final art = item['artwork'];
      String? artUrl;
      if (art is Map) {
        final big = art['480x480'] ?? art['150x150'] ?? art['1000x1000'];
        if (big is String && big.isNotEmpty) artUrl = big;
      }
      final duration = item['duration'];
      final downloadable = item['is_downloadable'] == true &&
          item['is_download_gated'] != true;
      if (onlyDownloadable && !downloadable) continue;
      final dateText = item['release_date'] ?? item['created_at'];
      result.add(OnlineTrack(
        id: id,
        title: title.trim(),
        artist: artist.isEmpty ? 'Unknown artist' : artist,
        durationSeconds: duration is num ? duration.round() : 0,
        streamUrl: '$host/v1/tracks/$id/stream?app_name=$appName',
        artworkUrl: artUrl,
        downloadable: downloadable,
        releasedAt: dateText is String ? DateTime.tryParse(dateText) : null,
      ));
    }
    return result;
  }
}
