import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'controllers/account_controller.dart';
import 'controllers/ambient_controller.dart';
import 'controllers/focus_controller.dart';
import 'controllers/library_controller.dart';
import 'controllers/online_controller.dart';
import 'controllers/player_controller.dart';
import 'controllers/playlist_controller.dart';
import 'controllers/scan_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/stats_controller.dart';
import 'core/events/event_bus.dart';
import 'handlers/account_handler.dart';
import 'handlers/ambient_handler.dart';
import 'handlers/favorite_handler.dart';
import 'handlers/history_handler.dart';
import 'handlers/notification_handler.dart';
import 'handlers/player_handler.dart';
import 'handlers/session_handler.dart';
import 'handlers/settings_handler.dart';
import 'handlers/system_notification_handler.dart';
import 'main_handlers.dart';
import 'repositories/account_repository.dart';
import 'repositories/database_helper.dart';
import 'repositories/history_repository.dart';
import 'repositories/playlist_repository.dart';
import 'repositories/session_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/track_repository.dart';
import 'services/ambient_service.dart';
import 'services/background_audio_handler.dart';
import 'services/download_service.dart';
import 'services/google_auth_service.dart';
import 'services/import_service.dart';
import 'services/online_service.dart';
import 'services/player_service.dart';
import 'services/scan_service.dart';
import 'services/system_notification_service.dart';
import 'services/tag_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. One event bus for the whole app
  final bus = EventBus();

  // 2. Repositories (database access)
  final db = DatabaseHelper.instance;
  final trackRepo = TrackRepository(db);
  final historyRepo = HistoryRepository(db);
  final sessionRepo = SessionRepository(db);
  final playlistRepo = PlaylistRepository(db);
  final accountRepo = AccountRepository(db);
  final settingsRepo = SettingsRepository(db);

  // 3. Services (audio, ambient loops, importing and scanning files)
  final playerService = PlayerService(bus);
  final ambientService = AmbientService(bus);
  final tagService = TagService();
  final importService = ImportService(trackRepo, bus, tags: tagService);
  final scanService = ScanService(trackRepo, bus, tags: tagService);
  final systemNotifications = SystemNotificationService();
  await systemNotifications.init();

  // 3b. Background playback: music keeps playing with the screen off and
  // shows notification and lock-screen controls. If the Android setup in the
  // README is missing, the app still works, only without background controls.
  try {
    await AudioService.init(
      builder: () => SoundSphereAudioHandler(playerService, bus),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.soundsphere.playback',
        androidNotificationChannelName: 'SoundSphere playback',
        androidNotificationOngoing: true,
      ),
    );
  } catch (e) {
    debugPrint('Background playback unavailable: $e');
  }

  // 4. Event handlers: each subscribes once and reacts independently
  final handlers = AppHandlers(
    player: PlayerHandler(bus, playerService, trackRepo, playlistRepo),
    ambient: AmbientHandler(bus, ambientService),
    session: SessionHandler(bus, sessionRepo),
    history: HistoryHandler(bus, historyRepo),
    favorite: FavoriteHandler(bus, trackRepo),
    notification: NotificationHandler(bus),
    account: AccountHandler(bus, accountRepo),
    systemNotification: SystemNotificationHandler(bus, systemNotifications),
    settings: SettingsHandler(bus, settingsRepo),
  )..initAll();

  // 5. Controllers (MVC): the screens talk to these
  final library = LibraryController(bus, trackRepo, historyRepo, importService);
  final stats = StatsController(bus, sessionRepo);
  final playlists = PlaylistController(playlistRepo);
  final account =
      AccountController(bus, accountRepo, google: GoogleAuthService());
  final focus = FocusController(bus);
  final settings =
      SettingsController(bus, settingsRepo, historyRepo, sessionRepo);
  final scan = ScanController(scanService);
  final onlineService = OnlineService();
  final online = OnlineController(bus, trackRepo, onlineService,
      downloads: DownloadService(onlineService));
  await library.load();
  await stats.refresh();
  await playlists.load();
  await account.init(); // restores the remembered user (or guest) session
  await settings.load(); // announces the saved preferences to every listener

  runApp(
    MultiProvider(
      providers: [
        Provider<AppHandlers>.value(value: handlers),
        ChangeNotifierProvider<AccountController>.value(value: account),
        ChangeNotifierProvider<LibraryController>.value(value: library),
        ChangeNotifierProvider<StatsController>.value(value: stats),
        ChangeNotifierProvider<PlaylistController>.value(value: playlists),
        ChangeNotifierProvider<PlayerController>.value(
            value: PlayerController(bus, playerService)),
        ChangeNotifierProvider<FocusController>.value(value: focus),
        ChangeNotifierProvider<AmbientController>.value(
            value: AmbientController(bus, ambientService)),
        ChangeNotifierProvider<SettingsController>.value(value: settings),
        ChangeNotifierProvider<ScanController>.value(value: scan),
        ChangeNotifierProvider<OnlineController>.value(value: online),
      ],
      child: const SoundSphereApp(),
    ),
  );
}
