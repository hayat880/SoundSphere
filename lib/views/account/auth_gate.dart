import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/account_controller.dart';
import '../app_shell.dart'; // ASSUMPTION: your shell widget is named AppShell
import 'log_in_screen.dart';

/// Shows the app when signed in or in guest mode, otherwise the login screen.
/// Use it where the splash screen currently navigates to AppShell.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AccountController>().status;
    switch (status) {
      case AuthStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.signedOut:
        return const LogInScreen();
      case AuthStatus.signedIn:
      case AuthStatus.guest:
        return const AppShell();
    }
  }
}
