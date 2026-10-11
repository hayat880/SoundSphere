import 'package:flutter/foundation.dart';

import '../services/scan_service.dart';

enum ScanStatus { idle, requesting, scanning, done, denied, permanentlyDenied, failed }

/// Drives the Scan screen: asks for permission, runs the scan and exposes
/// progress. The result is announced on the event bus by [ScanService].
class ScanController extends ChangeNotifier {
  ScanController(this._service);
  final ScanService _service;

  ScanStatus status = ScanStatus.idle;
  int found = 0;
  int added = 0;
  String currentFolder = '';

  bool get busy =>
      status == ScanStatus.requesting || status == ScanStatus.scanning;

  Future<void> start() async {
    if (busy) return;
    status = ScanStatus.requesting;
    notifyListeners();

    final permission = await _service.requestPermission();
    if (permission != ScanPermission.granted) {
      status = permission == ScanPermission.permanentlyDenied
          ? ScanStatus.permanentlyDenied
          : ScanStatus.denied;
      notifyListeners();
      return;
    }

    found = 0;
    added = 0;
    currentFolder = '';
    status = ScanStatus.scanning;
    notifyListeners();

    try {
      final result = await _service.scan(onProgress: (count, folder) {
        found = count;
        currentFolder = folder;
        if (count % 5 == 0) notifyListeners();
      });
      found = result.filesFound;
      added = result.added;
      status = ScanStatus.done;
    } catch (e) {
      debugPrint('Scan failed: $e');
      status = ScanStatus.failed;
    }
    notifyListeners();
  }

  Future<void> openSettings() => _service.openSystemSettings();
}
