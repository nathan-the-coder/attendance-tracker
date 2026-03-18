import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';

class Folder {
  final String id;
  final String name;
  final DateTime createdAt;
  List<Student> students;

  Folder({
    required this.id,
    required this.name,
    required this.createdAt,
    List<Student>? students,
  }) : students = students ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'students': students.map((s) => s.toJsonString()).toList(),
  };

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      students: (json['students'] as List<dynamic>?)
          ?.map((s) => Student.fromJsonString(s))
          .toList() ?? [],
    );
  }
}

class FolderProvider extends ChangeNotifier {
  List<Folder> _folders = [];
  String? _selectedFolderId;

  List<Folder> get folders => _folders;
  String? get selectedFolderId => _selectedFolderId;
  
  Folder? get selectedFolder => 
      _selectedFolderId != null 
          ? _folders.firstWhere((f) => f.id == _selectedFolderId, orElse: () => _folders.first)
          : null;

  FolderProvider() {
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('folders');
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      _folders = jsonList.map((e) => Folder.fromJson(e)).toList();
      if (_folders.isNotEmpty) {
        _selectedFolderId = _folders.first.id;
      }
      notifyListeners();
    }
  }

  Future<void> _saveFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(_folders.map((f) => f.toJson()).toList());
    await prefs.setString('folders', data);
  }

  void createFolder(String name) {
    final folder = Folder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
    );
    _folders.add(folder);
    if (_selectedFolderId == null) {
      _selectedFolderId = folder.id;
    }
    _saveFolders();
    notifyListeners();
  }

  void deleteFolder(String id) {
    _folders.removeWhere((f) => f.id == id);
    if (_selectedFolderId == id) {
      _selectedFolderId = _folders.isNotEmpty ? _folders.first.id : null;
    }
    _saveFolders();
    notifyListeners();
  }

  void selectFolder(String id) {
    _selectedFolderId = id;
    notifyListeners();
  }

  void renameFolder(String id, String newName) {
    final index = _folders.indexWhere((f) => f.id == id);
    if (index != -1) {
      _folders[index] = Folder(
        id: _folders[index].id,
        name: newName,
        createdAt: _folders[index].createdAt,
        students: _folders[index].students,
      );
      _saveFolders();
      notifyListeners();
    }
  }

  void addStudentToFolder(String folderId, Student student) {
    final index = _folders.indexWhere((f) => f.id == folderId);
    if (index != -1) {
      _folders[index].students.add(student);
      _saveFolders();
      notifyListeners();
    }
  }

  void removeStudentFromFolder(String folderId, String studentId) {
    final index = _folders.indexWhere((f) => f.id == folderId);
    if (index != -1) {
      _folders[index].students.removeWhere((s) => s.id == studentId);
      _saveFolders();
      notifyListeners();
    }
  }

  Future<void> downloadFolder(Folder folder) async {
    try {
      Directory? directory;
      
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }
      
      if (directory == null) {
        directory = await getApplicationDocumentsDirectory();
      }
      
      final folderDir = Directory('${directory.path}/${folder.name.replaceAll(' ', '_')}_QRCodes');
      if (await folderDir.exists()) {
        await folderDir.delete(recursive: true);
      }
      await folderDir.create(recursive: true);

      for (final student in folder.students) {
        final qrData = student.toJsonString();
        final fileName = '${student.firstName}_${student.middleName}_${student.lastName}.png'.toLowerCase();
        final file = File('${folderDir.path}/$fileName');
        
        final image = await QrPainter(
          data: qrData,
          version: QrVersions.auto,
        ).toImage(300);
        
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        await file.writeAsBytes(byteData!.buffer.asUint8List());
      }

      final manifestFile = File('${folderDir.path}/manifest.txt');
      final manifestContent = folder.students.map((s) => 
        'Name: ${s.fullName}\nProgram: ${s.program}\nYear: ${s.year}\nID: ${s.id}\n'
      ).join('\n---\n');
      await manifestFile.writeAsString(manifestContent);
    } catch (e) {
      debugPrint('Error downloading folder: $e');
    }
  }
}
