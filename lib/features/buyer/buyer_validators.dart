// These checks are used only for buyer signup.
class BuyerValidators {
  BuyerValidators._();

  // The buyer must enter a name.
  static String? name(String? value) {
    return (value?.trim().isEmpty ?? true) ? 'Enter your full name.' : null;
  }

  // The buyer must enter a valid email address.
  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  // The signup password must have at least 8 characters.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password.';
    if (value.length < 8) return 'Use at least 8 characters.';
    return null;
  }

  // Both passwords must match.
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm your password.';
    return value != password ? 'Passwords do not match.' : null;
  }
}
