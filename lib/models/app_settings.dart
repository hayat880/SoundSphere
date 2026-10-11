/// User preferences saved on the device (see SettingsRepository).
class AppSettings {
  const AppSettings({
    this.notificationsEnabled = true,
    this.autoBreak = true,
    this.breakSeconds = 5 * 60,
    this.focusSeconds = 25 * 60,
  });

  /// Phone notifications when a session or break ends in the background.
  final bool notificationsEnabled;

  /// Start a break automatically after each completed session.
  final bool autoBreak;
  final int breakSeconds;

  /// Default length of a focus session.
  final int focusSeconds;

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? autoBreak,
    int? breakSeconds,
    int? focusSeconds,
  }) =>
      AppSettings(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        autoBreak: autoBreak ?? this.autoBreak,
        breakSeconds: breakSeconds ?? this.breakSeconds,
        focusSeconds: focusSeconds ?? this.focusSeconds,
      );

  Map<String, String> toMap() => {
        'notifications': '$notificationsEnabled',
        'auto_break': '$autoBreak',
        'break_seconds': '$breakSeconds',
        'focus_seconds': '$focusSeconds',
      };

  /// Missing or unreadable values fall back to the defaults.
  factory AppSettings.fromMap(Map<String, String> m) {
    const d = AppSettings();
    bool flag(String key, bool fallback) =>
        m[key] == null ? fallback : m[key] == 'true';
    int number(String key, int fallback) {
      final v = int.tryParse(m[key] ?? '');
      return (v == null || v <= 0) ? fallback : v;
    }

    return AppSettings(
      notificationsEnabled: flag('notifications', d.notificationsEnabled),
      autoBreak: flag('auto_break', d.autoBreak),
      breakSeconds: number('break_seconds', d.breakSeconds),
      focusSeconds: number('focus_seconds', d.focusSeconds),
    );
  }
}
