class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    this.lastName,
  });

  final String id;
  final String email;
  final String firstName;
  final String? lastName;

  String get displayName {
    final fullName = '$firstName ${lastName ?? ''}'.trim();
    return fullName.isEmpty ? email : fullName;
  }
}
