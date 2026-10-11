import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';

import '../core/app_config.dart';

/// The name and email Google gave us after a successful sign-in.
class GoogleIdentity {
  const GoogleIdentity(this.name, this.email);
  final String name;
  final String email;
}

/// Google sign-in cannot start until the app is registered in Google Cloud.
class GoogleSetupException implements Exception {
  GoogleSetupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Thin wrapper around the google_sign_in package (version 7 API), so the
/// rest of the app never touches the plugin and tests can use a fake.
class GoogleAuthService {
  bool _ready = false;

  /// The "Web application" OAuth client id from Google Cloud Console. Android
  /// needs it. Pass it when running:
  /// flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
  static String get serverClientId {
    const fromRunArgs = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    return fromRunArgs.isNotEmpty
        ? fromRunArgs
        : AppConfig.googleServerClientId.trim();
  }

  /// False on Android until a Web client ID is set. The login screen hides
  /// the Google button in that case, so nobody sees a setup error.
  bool get isConfigured => !Platform.isAndroid || serverClientId.isNotEmpty;

  /// Returns null when the person closes the Google sheet without choosing.
  /// Throws for real problems, such as a missing Google Cloud setup.
  Future<GoogleIdentity?> signIn() async {
    if (Platform.isAndroid && serverClientId.isEmpty) {
      throw GoogleSetupException(
          'Google sign-in needs a one-time setup. Paste your Web client ID '
          'into lib/core/app_config.dart (README: "Google sign-in setup"). '
          'Until then, use email login or Continue offline.');
    }
    final google = GoogleSignIn.instance;
    if (!_ready) {
      await google.initialize(
        serverClientId: serverClientId.isEmpty ? null : serverClientId,
      );
      _ready = true;
    }
    try {
      final account = await google.authenticate();
      final name = (account.displayName ?? '').trim();
      return GoogleIdentity(
        name.isEmpty ? account.email.split('@').first : name,
        account.email,
      );
    } on Exception catch (e) {
      if (e.toString().toLowerCase().contains('cancel')) return null;
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!_ready) return;
    try {
      await GoogleSignIn.instance.signOut();
    } on Exception {
      // Signing out of Google is best effort.
    }
  }
}
