import '../../models/user_profile.dart';
import 'app_event.dart';

/// Facts about the account. Controllers publish them, handlers react.
class AccountCreated extends AppEvent {
  final UserProfile profile;
  AccountCreated(this.profile);
}

class AccountLoggedIn extends AppEvent {
  final UserProfile profile;
  AccountLoggedIn(this.profile);
}

class AccountLoggedOut extends AppEvent {}

class GuestModeEntered extends AppEvent {}

class AccountUpdated extends AppEvent {
  final UserProfile profile;
  AccountUpdated(this.profile);
}
