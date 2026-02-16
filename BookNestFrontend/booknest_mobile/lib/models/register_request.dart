class RegisterRequest {
  final String firstName;
  final String lastName;
  final String emailAddress;
  final String username;
  final String password;
  final DateTime dateOfBirth;
  final String? address;
  final String? city;
  final String? country;
  final String? phoneNumber;
  final String? imageUrl;
  final List<int> roleIds;

  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.emailAddress,
    required this.username,
    required this.password,
    required this.dateOfBirth,
    this.address,
    this.city,
    this.country,
    this.phoneNumber,
    this.imageUrl,
    this.roleIds = const [3], // Default role ID 3 (User)
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'emailAddress': emailAddress,
      'username': username,
      'password': password,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'address': address,
      'city': city,
      'country': country,
      'phoneNumber': phoneNumber,
      'imageUrl': imageUrl,
      'roleIds': roleIds,
    };
  }
}