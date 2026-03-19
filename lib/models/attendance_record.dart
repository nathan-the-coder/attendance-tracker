import 'package:cloud_firestore/cloud_firestore.dart';
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

  Map<String, dynamic> toMap() => {
    'id': id,
    'student': student.toMap(),
    'timestamp': Timestamp.fromDate(timestamp),
    'type': type.name,
  };

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'],
      student: Student.fromMap(Map<String, dynamic>.from(map['student'])),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      type: AttendanceType.values.firstWhere((e) => e.name == map['type']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'student': student.toJson(),
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
  };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      student: Student.fromJson(json['student']),
      timestamp: DateTime.parse(json['timestamp']),
      type: AttendanceType.values.firstWhere((e) => e.name == json['type']),
    );
  }
}
