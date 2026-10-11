import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/account_controller.dart';
import 'log_in_screen.dart';
import 'sign_up_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _rename(BuildContext context, AccountController c) async {
    final ctrl = TextEditingController(text: c.profile?.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, ctrl.text),
              child: const Text('Save')),
        ],
      ),
    );
    if (name != null) await c.rename(name);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AccountController>();
    final p = c.profile;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: scheme.primaryContainer,
              child: Text(p?.initials ?? '🎧',
                  style: TextStyle(fontSize: 28, color: scheme.onPrimaryContainer)),
            ),
          ),
          const SizedBox(height: 16),
          if (p != null) ...[
            Center(child: Text(p.name, style: Theme.of(context).textTheme.titleLarge)),
            Center(child: Text(p.email)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit name'),
              onTap: () => _rename(context, c),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () {
                c.logOut(); // AuthGate shows the login screen
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
            ),
          ] else ...[
            Center(
                child: Text('Offline mode',
                    style: Theme.of(context).textTheme.titleLarge)),
            const Center(child: Text('Your music and focus data stay on this device.')),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const SignUpScreen())),
              child: const Text('Create an account'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const LogInScreen())),
              child: const Text('Log in'),
            ),
          ],
        ],
      ),
    );
  }
}
