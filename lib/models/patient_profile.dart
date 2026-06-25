// lib/models/patient_profile.dart
class PatientProfile {
  final String uid;
  final String name;
  final String email;
  final int? age;

  const PatientProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.age,
  });

  Map<String, dynamic> toMap() => {
    "uid": uid,
    "name": name,
    "email": email,
    "age": age,
  };
}
