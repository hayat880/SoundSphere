String? validateName(String? v) =>
    (v == null || v.trim().length < 2) ? 'Enter your name' : null;

String? validateEmail(String? v) {
  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim());
  return ok ? null : 'Enter a valid email';
}

String? validatePassword(String? v) =>
    (v == null || v.length < 6) ? 'At least 6 characters' : null;
