import 'dart:convert';
import 'student.dart';

enum AttendanceType { timeIn, timeOut }

class AttendanceRecord {
  final String id;
  final Student student;
  final DateTime timestamp;
  final AttendanceType type;

  AttendanceRecord({
    required this.id,
    required this.student,
    required this.timestamp,
    required this.type,
  });

  String toJsonString() => jsonEncode({
    'id': id,
    'student': student.toJsonString(),
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
  });

  factory AttendanceRecord.fromJsonString(String jsonString) {
    final map = jsonDecode(jsonString);
    return AttendanceRecord(
      id: map['id'],
      student: Student.fromJsonString(map['student']),
      timestamp: DateTime.parse(map['timestamp']),
      type: AttendanceType.values.firstWhere((e) => e.name == map['type']),
    );
  }
}
