class User {
  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String emailAddress;
  final String username;
  final String? imageUrl;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.emailAddress,
    required this.username,
    this.imageUrl,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      fullName: json['fullName'] ?? '',
      emailAddress: json['emailAddress'] ?? '',
      username: json['username'] ?? '',
      imageUrl: (json['imageUrl'] as String?)?.trim().isEmpty == true
          ? null
          : json['imageUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
