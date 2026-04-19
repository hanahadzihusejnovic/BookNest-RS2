class User {
  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String emailAddress;
  final String username;
  final DateTime? dateOfBirth;
  final String? address;
  final String? city;
  final String? country;
  final String? phoneNumber;
  final String? imageUrl;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.emailAddress,
    required this.username,
    this.dateOfBirth,
    this.address,
    this.city,
    this.country,
    this.phoneNumber,
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
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      address: json['address'],
      city: json['city'],
      country: json['country'],
      phoneNumber: json['phoneNumber'],
      imageUrl: (json['imageUrl'] as String?)?.trim().isEmpty == true
          ? null
          : json['imageUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
