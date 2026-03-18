import 'dart:convert';

class Student {
  final String id;
  final String firstName;
  final String middleName;
  final String lastName;
  final String year;
  final String program;

  Student({
    required this.id,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.year,
    required this.program,
  });

  String get fullName => '$firstName $middleName $lastName'.replaceAll(RegExp(r'\s+'), ' ').trim();

  String toJsonString() => jsonEncode({
    'id': id,
    'firstName': firstName,
    'middleName': middleName,
    'lastName': lastName,
    'year': year,
    'program': program,
  });

  factory Student.fromJsonString(String jsonString) {
    final map = jsonDecode(jsonString);
    return Student(
      id: map['id'],
      firstName: map['firstName'],
      middleName: map['middleName'],
      lastName: map['lastName'],
      year: map['year'],
      program: map['program'],
    );
  }
}
