import 'dart:io';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/student.dart';

class Section {
  final String id;
  final String name;
  final DateTime createdAt;
  List<Student> students;

  Section({
    required this.id,
    required this.name,
    required this.createdAt,
    List<Student>? students,
  }) : students = students ?? [];

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'createdAt': Timestamp.fromDate(createdAt),
    'students': students.map((s) => s.toMap()).toList(),
  };

  factory Section.fromMap(Map<String, dynamic> map) {
    return Section(
      id: map['id'],
      name: map['name'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      students:
          (map['students'] as List<dynamic>?)
              ?.map((s) => Student.fromMap(Map<String, dynamic>.from(s)))
              .toList() ??
          [],
    );
  }
}

class FolderProvider extends ChangeNotifier {
  List<Section> _sections = [];
  String? _selectedFolderId;
  bool _isLoading = true;
  final _uuid = const Uuid();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Section> get sections => _sections;
  List<Section> get folders => _sections;
  String? get selectedFolderId => _selectedFolderId;
  bool get isLoading => _isLoading;

  Section? get selectedFolder => _selectedFolderId != null
      ? _sections.firstWhere(
          (f) => f.id == _selectedFolderId,
          orElse: () => _sections.first,
        )
      : _sections.isNotEmpty
      ? _sections.first
      : null;

  FolderProvider() {
    _loadSections();
  }

  Future<void> _loadSections() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('sections').get();
      _sections = snapshot.docs
          .map((doc) => Section.fromMap(doc.data()))
          .toList();
      if (_sections.isNotEmpty) {
        _selectedFolderId = _sections.first.id;
      }
    } catch (e) {
      debugPrint('Error loading sections: $e');
      _sections = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createSection(String name) async {
    final section = Section(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
    );

    try {
      await _firestore
          .collection('sections')
          .doc(section.id)
          .set(section.toMap());
      _sections.add(section);
      if (_selectedFolderId == null) {
        _selectedFolderId = section.id;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating section: $e');
    }
  }

  Future<void> deleteSection(String id) async {
    try {
      await _firestore.collection('sections').doc(id).delete();
      _sections.removeWhere((f) => f.id == id);
      if (_selectedFolderId == id) {
        _selectedFolderId = _sections.isNotEmpty ? _sections.first.id : null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting section: $e');
    }
  }

  void selectFolder(String id) {
    _selectedFolderId = id;
    notifyListeners();
  }

  Future<void> renameSection(String id, String newName) async {
    final index = _sections.indexWhere((f) => f.id == id);
    if (index != -1) {
      try {
        final updatedSection = Section(
          id: _sections[index].id,
          name: newName,
          createdAt: _sections[index].createdAt,
          students: _sections[index].students,
        );
        await _firestore
            .collection('sections')
            .doc(id)
            .update(updatedSection.toMap());
        _sections[index] = updatedSection;
        notifyListeners();
      } catch (e) {
        debugPrint('Error renaming section: $e');
      }
    }
  }

  Future<void> addStudentToSection(String sectionId, Student student) async {
    final index = _sections.indexWhere((f) => f.id == sectionId);
    if (index != -1) {
      try {
        _sections[index].students.add(student);
        await _firestore.collection('sections').doc(sectionId).update({
          'students': _sections[index].students.map((s) => s.toMap()).toList(),
        });
        notifyListeners();
      } catch (e) {
        debugPrint('Error adding student: $e');
      }
    }
  }

  Future<void> removeStudentFromSection(
    String sectionId,
    String studentId,
  ) async {
    final index = _sections.indexWhere((f) => f.id == sectionId);
    if (index != -1) {
      try {
        _sections[index].students.removeWhere((s) => s.id == studentId);
        await _firestore.collection('sections').doc(sectionId).update({
          'students': _sections[index].students.map((s) => s.toMap()).toList(),
        });
        notifyListeners();
      } catch (e) {
        debugPrint('Error removing student: $e');
      }
    }
  }

  Future<void> downloadSection(Section section) async {
    try {
      Directory? directory;

      if (Platform.isAndroid) {
        // For Android 10+, use app's external storage
        // This doesn't require any permissions
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final qrDir = Directory('${extDir.path}/QR_Codes');
          if (!await qrDir.exists()) {
            await qrDir.create(recursive: true);
          }
          directory = qrDir;
        } else {
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        directory =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      }

      final folderDir = Directory(
        '${directory.path}/${section.name.replaceAll(' ', '_')}_QRCodes',
      );
      if (await folderDir.exists()) {
        await folderDir.delete(recursive: true);
      }
      await folderDir.create(recursive: true);

      for (final student in section.students) {
        final qrData = student.toJsonString();
        final fileName =
            '${student.firstName}_${student.middleName}_${student.lastName}.png'
                .toLowerCase()
                .replaceAll(' ', '_');
        final file = File('${folderDir.path}/$fileName');

        final image = await QrPainter(
          data: qrData,
          version: QrVersions.auto,
        ).toImage(300);

        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        await file.writeAsBytes(byteData!.buffer.asUint8List());
      }

      final manifestFile = File('${folderDir.path}/manifest.txt');
      final manifestContent = section.students
          .map(
            (s) =>
                'Name: ${s.fullName}\nProgram: ${s.program}\nYear: ${s.year}\nID: ${s.id}\n',
          )
          .join('\n---\n');
      await manifestFile.writeAsString(manifestContent);
    } catch (e) {
      debugPrint('Error downloading section: $e');
    }
  }

  Future<void> createFolder(String name) => createSection(name);
  Future<void> deleteFolder(String id) => deleteSection(id);
  Future<void> renameFolder(String id, String newName) =>
      renameSection(id, newName);
  Future<void> addStudentToFolder(String sectionId, Student student) =>
      addStudentToSection(sectionId, student);
  Future<void> removeStudentFromFolder(String sectionId, String studentId) =>
      removeStudentFromSection(sectionId, studentId);
  Future<void> downloadFolder(Section section) => downloadSection(section);
}
