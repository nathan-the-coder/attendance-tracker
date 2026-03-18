import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';

class Day {
  final String id;
  final String name;
  final DateTime createdAt;
  List<AttendanceRecord> records;

  Day({
    required this.id,
    required this.name,
    required this.createdAt,
    List<AttendanceRecord>? records,
  }) : records = records ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'records': records.map((r) => r.toJsonString()).toList(),
  };

  factory Day.fromJson(Map<String, dynamic> json) {
    return Day(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      records: (json['records'] as List<dynamic>?)
          ?.map((r) => AttendanceRecord.fromJsonString(r))
          .toList() ?? [],
    );
  }
}

class DayProvider extends ChangeNotifier {
  List<Day> _days = [];
  String? _selectedDayId;

  List<Day> get days => _days;
  String? get selectedDayId => _selectedDayId;
  
  Day? get selectedDay => 
      _selectedDayId != null 
          ? _days.firstWhere((d) => d.id == _selectedDayId, orElse: () => _days.first)
          : null;

  DayProvider() {
    _loadDays();
  }

  Future<void> _loadDays() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('days');
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      _days = jsonList.map((e) => Day.fromJson(e)).toList();
      if (_days.isNotEmpty) {
        _selectedDayId = _days.first.id;
      }
      notifyListeners();
    }
  }

  Future<void> _saveDays() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(_days.map((d) => d.toJson()).toList());
    await prefs.setString('days', data);
  }

  void createDay(String name) {
    final day = Day(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
    );
    _days.insert(0, day);
    if (_selectedDayId == null) {
      _selectedDayId = day.id;
    }
    _saveDays();
    notifyListeners();
  }

  void deleteDay(String id) {
    _days.removeWhere((d) => d.id == id);
    if (_selectedDayId == id) {
      _selectedDayId = _days.isNotEmpty ? _days.first.id : null;
    }
    _saveDays();
    notifyListeners();
  }

  void selectDay(String id) {
    _selectedDayId = id;
    notifyListeners();
  }

  void renameDay(String id, String newName) {
    final index = _days.indexWhere((d) => d.id == id);
    if (index != -1) {
      _days[index] = Day(
        id: _days[index].id,
        name: newName,
        createdAt: _days[index].createdAt,
        records: _days[index].records,
      );
      _saveDays();
      notifyListeners();
    }
  }

  bool hasTimeIn(String dayId, String studentId) {
    final dayIndex = _days.indexWhere((d) => d.id == dayId);
    if (dayIndex == -1) return false;
    return _days[dayIndex].records.any(
      (r) => r.student.id == studentId && r.type == AttendanceType.timeIn
    );
  }

  bool hasTimeOut(String dayId, String studentId) {
    final dayIndex = _days.indexWhere((d) => d.id == dayId);
    if (dayIndex == -1) return false;
    return _days[dayIndex].records.any(
      (r) => r.student.id == studentId && r.type == AttendanceType.timeOut
    );
  }

  void addRecordToDay(String dayId, AttendanceRecord record) {
    final index = _days.indexWhere((d) => d.id == dayId);
    if (index != -1) {
      _days[index].records.insert(0, record);
      _saveDays();
      notifyListeners();
    }
  }

  void clearDayRecords(String dayId) {
    final index = _days.indexWhere((d) => d.id == dayId);
    if (index != -1) {
      _days[index].records.clear();
      _saveDays();
      notifyListeners();
    }
  }
}
