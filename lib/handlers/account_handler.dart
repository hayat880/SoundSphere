import 'dart:async';

import '../core/events/account_events.dart';
import '../core/events/event_bus.dart';
import '../repositories/account_repository.dart';

/// Independent listener. Remembers who is signed in so the next launch can
/// skip the login screen. The AccountController does not know it exists.
class AccountHandler {
  AccountHandler(this._bus, this._repo);
  final EventBus _bus;
  final AccountRepository _repo;
  final List<StreamSubscription> _subs = [];

  void init() {
    dispose(); // never subscribe twice
    _subs.add(_bus.on<AccountCreated>().listen(
        (e) => _repo.saveSession('user:${e.profile.id}')));
    _subs.add(_bus.on<AccountLoggedIn>().listen(
        (e) => _repo.saveSession('user:${e.profile.id}')));
    _subs.add(_bus.on<GuestModeEntered>().listen((_) => _repo.saveSession('guest')));
    _subs.add(_bus.on<AccountLoggedOut>().listen((_) => _repo.saveSession(null)));
  }

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }
}
