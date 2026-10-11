/// Settings you fill in once.
class AppConfig {
  /// The "Web application" OAuth client id from Google Cloud Console
  /// (it ends in .apps.googleusercontent.com). Android needs it for
  /// "Continue with Google". Leave it empty to run without Google sign-in.
  /// See the README section "Google sign-in setup".
  static const String googleServerClientId = '';
}
