/// A patient file.
class Patient {
  final String id;
  final String firstName;
  final String surname;
  final DateTime? dateOfBirth;
  final String sexAtBirth;
  final String gender;
  final String? genderDescription;
  final String phoneNumber;
  final String? email;
  final String address;

  Patient({
    required this.id,
    required this.firstName,
    required this.surname,
    this.dateOfBirth,
    required this.sexAtBirth,
    required this.gender,
    this.genderDescription,
    required this.phoneNumber,
    this.email,
    required this.address,
  });
}