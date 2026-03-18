import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  AttendanceProvider() {
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('attendance_records');
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      _records = jsonList.map((e) => AttendanceRecord.fromJsonString(e)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(_records.map((r) => r.toJsonString()).toList());
    await prefs.setString('attendance_records', data);
  }

  void addRecord(Student student, AttendanceType type) {
    final record = AttendanceRecord(
      id: _uuid.v4(),
      student: student,
      timestamp: DateTime.now(),
      type: type,
    );
    _records.insert(0, record);
    _saveRecords();
    notifyListeners();
  }

  void clearRecords() {
    _records.clear();
    _saveRecords();
    notifyListeners();
  }
}
