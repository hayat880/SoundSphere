import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/account_controller.dart';
import 'sign_up_screen.dart';
import 'validators.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});
  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hide = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final ok = await context
        .read<AccountController>()
        .logIn(_email.text, _password.text);
    // When this screen was pushed from Account, close it on success.
    if (ok && mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _google() async {
    final ok = await context.read<AccountController>().signInWithGoogle();
    if (ok && mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void _offline() {
    context.read<AccountController>().continueOffline();
    // When this screen was opened from Account (already offline), the gate has
    // nothing to swap, so close back to the app ourselves.
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AccountController>();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.graphic_eq, size: 56, color: scheme.primary),
                    const SizedBox(height: 12),
                    Text('SoundSphere',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium),
                    Text('music, focus and balance',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                      validator: validateEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: _hide,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _hide = !_hide),
                        ),
                      ),
                      validator: validatePassword,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (c.error != null) ...[
                      const SizedBox(height: 12),
                      Text(c.error!, style: TextStyle(color: scheme.error)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: c.busy ? null : _submit,
                      child: c.busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Log in'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignUpScreen())),
                      child: const Text("Don't have an account? Sign up"),
                    ),
                    const Divider(height: 32),
                    if (c.googleAvailable) ...[
                      OutlinedButton.icon(
                        onPressed: c.busy ? null : _google,
                        icon: const Text('G',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        label: const Text('Continue with Google'),
                      ),
                      const SizedBox(height: 10),
                    ],
                    OutlinedButton(
                      onPressed: _offline,
                      child: const Text('Continue offline'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
