class Validators {
  static String? required(String? v, [String label = 'Field']) =>
      (v == null || v.trim().isEmpty) ? 'Enter $label' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your email';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()) ? null : 'Invalid email';
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your phone number';
    return RegExp(r'^(09\d{9}|\+639\d{9})$').hasMatch(v.trim()) ? null : 'Use the format 09XXXXXXXXX';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Enter your password';
    if (v.length < 8) return 'At least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) return 'Must contain letters and numbers';
    return null;
  }
}
