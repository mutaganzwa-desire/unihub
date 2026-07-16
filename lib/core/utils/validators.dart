/// Reusable form validators. Pure functions => trivially unit-testable.
abstract final class Validators {
  static final _emailRe =
      RegExp(r"^[\w.!#$%&'*+/=?^`{|}~-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$");
  static final _urlRe = RegExp(r'^https?://[^\s]+$');
  static final _phoneRe = RegExp(r'^\+?[0-9\s\-()]{7,15}$');

  static String? required(String? v, [String field = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  static String? email(String? v) {
    final r = required(v, 'Email');
    if (r != null) return r;
    return _emailRe.hasMatch(v!.trim()) ? null : 'Enter a valid email address';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Use at least 8 characters';
    if (!v.contains(RegExp('[A-Za-z]')) || !v.contains(RegExp('[0-9]'))) {
      return 'Use letters and numbers';
    }
    return null;
  }

  static String? confirmPassword(String? v, String original) =>
      v != original ? 'Passwords do not match' : null;

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    return _phoneRe.hasMatch(v.trim()) ? null : 'Enter a valid phone number';
  }

  static String? url(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    return _urlRe.hasMatch(v.trim()) ? null : 'Enter a full URL (https://...)';
  }

  static String? maxLen(String? v, int max) =>
      (v != null && v.length > max) ? 'Maximum $max characters' : null;
}
