class AppValidators {
  const AppValidators._();

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email address is required.';
    if (email.length > 320) return 'Email address is too long.';
    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    if (!valid) return 'Enter a valid email address.';
    return null;
  }

  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length > 128) return 'Password must not exceed 128 characters.';
    return null;
  }

  static String? registrationPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Password must contain at least 8 characters.';
    if (value.length > 128) return 'Password must not exceed 128 characters.';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm your password.';
    if (value != password) return 'Passwords do not match.';
    return null;
  }

  static String? firstName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'First name is required.';
    if (text.length > 100) return 'First name must not exceed 100 characters.';
    return null;
  }

  static String? optionalLastName(String? value) {
    if ((value?.trim().length ?? 0) > 100) {
      return 'Last name must not exceed 100 characters.';
    }
    return null;
  }
}
