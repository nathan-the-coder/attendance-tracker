import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';
import '../providers/day_provider.dart';
import '../providers/folder_provider.dart';

class ManualAttendanceScreen extends StatefulWidget {
  const ManualAttendanceScreen({super.key});

  @override
  State<ManualAttendanceScreen> createState() => _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState extends State<ManualAttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Student> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Searches for students by name (first, middle, or last)
  /// Shows all students if search is empty
  void _searchStudents(String query) {
    final folderProvider = context.read<FolderProvider>();
    final allStudents = <Student>[];

    // Collect all students from all sections
    for (final section in folderProvider.sections) {
      allStudents.addAll(section.students);
    }

    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _searchResults.addAll(allStudents);
        _isSearching = false;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _isSearching = true;
      _searchResults.clear();
      _searchResults.addAll(
        allStudents.where((student) {
          return student.fullName.toLowerCase().contains(lowerQuery) ||
              student.program.toLowerCase().contains(lowerQuery) ||
              student.year.toLowerCase().contains(lowerQuery);
        }),
      );
    });
  }

  /// Shows dialog to select attendance type and confirm
  void _showAttendanceDialog(Student student) {
    final dayProvider = context.read<DayProvider>();

    if (dayProvider.selectedDayId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Day first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Mark Attendance for ${student.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${student.program} - ${student.year}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            const Text('Select attendance type:'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _markAttendance(student, AttendanceType.timeIn);
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Time In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF457507),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _markAttendance(student, AttendanceType.timeOut);
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Time Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Marks attendance for a student
  void _markAttendance(Student student, AttendanceType type) {
    final dayProvider = context.read<DayProvider>();
    final dayId = dayProvider.selectedDayId!;

    // Check for duplicates (same logic as scanner)
    if (type == AttendanceType.timeIn &&
        dayProvider.hasTimeIn(dayId, student.id)) {
      _showOverrideDialog(student, type);
      return;
    }

    if (type == AttendanceType.timeOut &&
        dayProvider.hasTimeOut(dayId, student.id)) {
      _showOverrideDialog(student, type);
      return;
    }

    // No duplicate - record directly
    _recordAttendance(student, type);
  }

  /// Shows dialog to confirm override when duplicate detected
  void _showOverrideDialog(Student student, AttendanceType type) {
    final typeText = type == AttendanceType.timeIn ? 'Time In' : 'Time Out';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('Duplicate Entry'),
          ],
        ),
        content: Text(
          '${student.fullName} already has $typeText recorded today.\n\nDo you want to update the time?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final dayProvider = context.read<DayProvider>();
              dayProvider.removeRecord(
                dayProvider.selectedDayId!,
                student.id,
                type,
              );
              _recordAttendance(student, type);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  /// Records attendance to Firestore
  void _recordAttendance(Student student, AttendanceType type) {
    final dayProvider = context.read<DayProvider>();
    final dayId = dayProvider.selectedDayId!;

    final record = AttendanceRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      student: student,
      timestamp: DateTime.now(),
      type: type,
    );

    dayProvider.addRecordToDay(dayId, record);

    final typeText = type == AttendanceType.timeIn ? 'Time In' : 'Time Out';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              type == AttendanceType.timeIn ? Icons.login : Icons.logout,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text('${student.fullName} - $typeText recorded!')),
          ],
        ),
        backgroundColor: type == AttendanceType.timeIn
            ? const Color(0xFF457507)
            : const Color(0xFFEF4444),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Manual Attendance',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Day selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Consumer<DayProvider>(
              builder: (context, dayProvider, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: dayProvider.selectedDayId,
                      isExpanded: true,
                      hint: const Text('Select Day'),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      items: dayProvider.days.map((day) {
                        return DropdownMenuItem(
                          value: day.id,
                          child: Text(day.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          dayProvider.selectDay(value);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search student by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchStudents('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFF59E0B),
                    width: 2,
                  ),
                ),
              ),
              onChanged: _searchStudents,
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_searchResults.length} students found',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Student list
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isSearching
                              ? 'No students found'
                              : 'Search for a student',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final student = _searchResults[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                          title: Text(
                            student.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '${student.program} - ${student.year}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _showAttendanceDialog(student),
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Color(0xFF457507),
                                ),
                                tooltip: 'Add Attendance',
                              ),
                            ],
                          ),
                          onTap: () => _showAttendanceDialog(student),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
