import 'handlers/account_handler.dart';
import 'handlers/ambient_handler.dart';
import 'handlers/favorite_handler.dart';
import 'handlers/history_handler.dart';
import 'handlers/notification_handler.dart';
import 'handlers/player_handler.dart';
import 'handlers/session_handler.dart';
import 'handlers/settings_handler.dart';
import 'handlers/system_notification_handler.dart';

/// Holds every event handler so they stay alive for the whole app.
class AppHandlers {
  AppHandlers({
    required this.player,
    required this.ambient,
    required this.session,
    required this.history,
    required this.favorite,
    required this.notification,
    required this.account,
    required this.systemNotification,
    required this.settings,
  });

  final PlayerHandler player;
  final AmbientHandler ambient;
  final SessionHandler session;
  final HistoryHandler history;
  final FavoriteHandler favorite;
  final NotificationHandler notification;
  final AccountHandler account;
  final SystemNotificationHandler systemNotification;
  final SettingsHandler settings;

  /// Each handler subscribes to the event bus exactly once, here.
  void initAll() {
    player.init();
    ambient.init();
    session.init();
    history.init();
    favorite.init();
    notification.init();
    account.init();
    systemNotification.init();
    settings.init();
  }
}
