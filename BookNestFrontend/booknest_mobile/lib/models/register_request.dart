class RegisterRequest {
  final String firstName;
  final String lastName;
  final String emailAddress;
  final String username;
  final String password;
  final DateTime dateOfBirth;
  final String? address;
  final int? cityId;
  final int? countryId;
  final String? phoneNumber;
  final String? imageUrl;

  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.emailAddress,
    required this.username,
    required this.password,
    required this.dateOfBirth,
    this.address,
    this.cityId,
    this.countryId,
    this.phoneNumber,
    this.imageUrl,
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
      'cityId': cityId,
      'countryId': countryId,
      'phoneNumber': phoneNumber,
      'imageUrl': imageUrl,
    };
  }
}