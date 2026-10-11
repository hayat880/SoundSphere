import 'package:flutter/foundation.dart';

import '../core/events/account_events.dart';
import '../core/events/event_bus.dart';
import '../models/user_profile.dart';
import '../repositories/account_repository.dart';
import '../services/google_auth_service.dart';

enum AuthStatus { loading, signedOut, signedIn, guest }

class AccountController extends ChangeNotifier {
  AccountController(this._bus, this._repo, {GoogleAuthService? google})
      : _google = google;
  final EventBus _bus;
  final AccountRepository _repo;
  final GoogleAuthService? _google;

  AuthStatus status = AuthStatus.loading;
  UserProfile? profile;
  String? error;
  bool busy = false;

  String get displayName => profile?.name.split(' ').first ?? 'there';

  /// Call once at startup (before the gate decides which screen to show).
  Future<void> init() async {
    final saved = await _repo.loadSession();
    if (saved == 'guest') {
      status = AuthStatus.guest;
    } else if (saved != null && saved.startsWith('user:')) {
      profile = await _repo.byId(int.parse(saved.substring(5)));
      status = profile == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    } else {
      status = AuthStatus.signedOut;
    }
    notifyListeners();
  }

  // Direct calls: one component is being asked to do something.
  Future<bool> signUp(String name, String email, String password) =>
      _run(() async {
        profile = await _repo.create(name, email, password);
        status = AuthStatus.signedIn;
        _bus.publish(AccountCreated(profile!));
      });

  Future<bool> logIn(String email, String password) => _run(() async {
        profile = await _repo.verify(email, password);
        status = AuthStatus.signedIn;
        _bus.publish(AccountLoggedIn(profile!));
      });

  /// Whether "Continue with Google" can work in this build.
  bool get googleAvailable => _google?.isConfigured ?? false;

  /// Returns true when signed in, false when cancelled or failed
  /// (a failure also sets [error]).
  Future<bool> signInWithGoogle() async {
    final google = _google;
    if (google == null) {
      error = 'Google sign-in is not available in this build.';
      notifyListeners();
      return false;
    }
    var cancelled = false;
    final ok = await _run(() async {
      final GoogleIdentity? who;
      try {
        who = await google.signIn();
      } on GoogleSetupException catch (e) {
        throw AccountException(e.message);
      } catch (e) {
        throw AccountException(
            'Google sign-in is not set up yet or failed. Check the '
            'README section "Google sign-in". ($e)');
      }
      if (who == null) {
        cancelled = true;
        return;
      }
      profile = await _repo.findOrCreateExternal(who.name, who.email);
      status = AuthStatus.signedIn;
      _bus.publish(AccountLoggedIn(profile!));
    });
    return ok && !cancelled;
  }

  void continueOffline() {
    error = null;
    profile = null;
    status = AuthStatus.guest;
    _bus.publish(GuestModeEntered());
    notifyListeners();
  }

  Future<void> rename(String name) async {
    final p = profile;
    if (p == null || name.trim().isEmpty) return;
    await _repo.rename(p.id, name);
    profile = p.copyWith(name: name.trim());
    _bus.publish(AccountUpdated(profile!));
    notifyListeners();
  }

  void logOut() {
    _google?.signOut();
    profile = null;
    status = AuthStatus.signedOut;
    _bus.publish(AccountLoggedOut());
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AccountException catch (e) {
      error = e.message;
      return false;
    } catch (_) {
      error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
