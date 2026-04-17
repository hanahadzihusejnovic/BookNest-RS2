class LoginResponse {
  final int userId;
  final String username;
  final String firstName;
  final String lastName;
  final String emailAddress;
  final List<String> roles;
  final String token;
  final DateTime expiresAt;

  LoginResponse({
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.emailAddress,
    required this.roles,
    required this.token,
    required this.expiresAt,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      userId: json['userId'],
      username: json['username'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      emailAddress: json['emailAddress'],
      roles: List<String>.from(json['roles']),
      token: json['token'],
      expiresAt: DateTime.parse(json['expiresAt']),
    );
  }
}
