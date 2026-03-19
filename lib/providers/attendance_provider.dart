import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';

class AttendanceProvider extends ChangeNotifier {
  List<AttendanceRecord> _records = [];
  final Uuid _uuid = const Uuid();

  List<AttendanceRecord> get records => _records;

  List<AttendanceRecord> get timeInRecords =>
      _records.where((r) => r.type == AttendanceType.timeIn).toList();

  List<AttendanceRecord> get timeOutRecords =>
      _records.where((r) => r.type == AttendanceType.timeOut).toList();

  void addRecord(Student student, AttendanceType type) {
    final record = AttendanceRecord(
      id: _uuid.v4(),
      student: student,
      timestamp: DateTime.now(),
      type: type,
    );
    _records.insert(0, record);
    notifyListeners();
  }

  void clearRecords() {
    _records.clear();
    notifyListeners();
  }
}
