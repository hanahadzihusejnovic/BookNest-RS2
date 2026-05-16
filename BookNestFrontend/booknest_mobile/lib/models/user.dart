class User {
  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String emailAddress;
  final String username;
  final DateTime dateOfBirth;
  final String? address;
  final int? cityId;
  final String? city;
  final int? countryId;
  final String? country;
  final String? phoneNumber;
  final String? imageUrl;
  final List<Role> roles;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.emailAddress,
    required this.username,
    required this.dateOfBirth,
    this.address,
    this.cityId,
    this.city,
    this.countryId,
    this.country,
    this.phoneNumber,
    this.imageUrl,
    required this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      fullName: json['fullName'],
      emailAddress: json['emailAddress'],
      username: json['username'],
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      address: json['address'],
      cityId: json['cityId'],
      city: json['cityName'],
      countryId: json['countryId'],
      country: json['countryName'],
      phoneNumber: json['phoneNumber'],
      imageUrl: json['imageUrl'],
      roles: (json['roles'] as List)
          .map((role) => Role.fromJson(role))
          .toList(),
    );
  }
}

class Role {
  final int id;
  final String name;

  Role({
    required this.id,
    required this.name,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      name: json['name'],
    );
  }
}