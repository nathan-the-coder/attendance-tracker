import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/student.dart';
import '../providers/folder_provider.dart';
import 'qr_display_screen.dart';

class FolderSectionScreen extends StatefulWidget {
  final String folderId;

  const FolderSectionScreen({super.key, required this.folderId});

  @override
  State<FolderSectionScreen> createState() => _FolderSectionScreenState();
}

class _FolderSectionScreenState extends State<FolderSectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String? _selectedYear;
  String? _selectedProgram;
  final Uuid _uuid = const Uuid();

  final List<String> _years = ['1st Year', '2nd Year', '3rd Year', '4th Year', '5th Year'];
  final List<String> _programs = ['BSIT', 'BSCS', 'BSBA', 'BSA', 'ABPOLSOC', 'ABENG', 'ABPSYCH', 'BSCE', 'BSEE', 'BSME'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _showAddStudentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Student',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Student Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _firstNameController,
                              decoration: _inputDecoration('First Name', Icons.person_outline),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter first name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _middleNameController,
                              decoration: _inputDecoration('Middle Name', Icons.person_outline),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter middle name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _lastNameController,
                              decoration: _inputDecoration('Last Name', Icons.person_outline),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter last name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              decoration: _inputDecoration('Year', Icons.school),
                              items: _years.map((year) {
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text(year),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedYear = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select year';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              decoration: _inputDecoration('Program', Icons.book),
                              items: _programs.map((program) {
                                return DropdownMenuItem(
                                  value: program,
                                  child: Text(program),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedProgram = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select program';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: _generateQr,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_2, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Generate QR Code',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generateQr() {
    if (_formKey.currentState!.validate()) {
      final folderProvider = context.read<FolderProvider>();
      final student = Student(
        id: _uuid.v4(),
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        year: _selectedYear!,
        program: _selectedProgram!,
      );

      folderProvider.addStudentToFolder(widget.folderId, student);

      _firstNameController.clear();
      _middleNameController.clear();
      _lastNameController.clear();
      setState(() {
        _selectedYear = null;
        _selectedProgram = null;
      });
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QrDisplayScreen(
            student: student,
            onDelete: () {
              context.read<FolderProvider>().removeStudentFromFolder(widget.folderId, student.id);
            },
          ),
        ),
      );
    }
  }

  void _showFolderOptions() {
    final folderProvider = context.read<FolderProvider>();
    final folder = folderProvider.folders.firstWhere((f) => f.id == widget.folderId);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder,
                size: 32,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              folder.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${folder.students.length} students',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF2563EB)),
              title: const Text('Rename Section'),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(folder.name);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Color(0xFF10B981)),
              title: const Text('Download All QR Codes'),
              onTap: () {
                Navigator.pop(ctx);
                folderProvider.downloadFolder(folder);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Downloaded ${folder.name} folder'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Section', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteFolder(folder.name);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Rename Section'),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Section Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<FolderProvider>().renameFolder(widget.folderId, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFolder(String folderName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Section?'),
        content: Text('Delete "$folderName"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<FolderProvider>().deleteFolder(widget.folderId);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Consumer<FolderProvider>(
          builder: (context, folderProvider, child) {
            final folder = folderProvider.folders.firstWhere(
              (f) => f.id == widget.folderId,
              orElse: () => Folder(id: '', name: 'Section', createdAt: DateTime.now()),
            );
            return Text(
              folder.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            );
          },
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showFolderOptions,
          ),
        ],
      ),
      body: Consumer<FolderProvider>(
        builder: (context, folderProvider, child) {
          final folder = folderProvider.folders.firstWhere(
            (f) => f.id == widget.folderId,
            orElse: () => Folder(id: '', name: '', createdAt: DateTime.now(), students: []),
          );

          if (folder.students.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No students yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add a student',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: folder.students.length,
            itemBuilder: (context, index) {
              final student = folder.students[index];
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
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  title: Text(
                    student.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${student.program} - ${student.year}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.qr_code, color: Color(0xFF2563EB)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QrDisplayScreen(
                                student: student,
                                onDelete: () {
                                  context.read<FolderProvider>().removeStudentFromFolder(widget.folderId, student.id);
                                },
                              ),
                            ),
                          );
                        },
                        tooltip: 'View QR',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          folderProvider.removeStudentFromFolder(widget.folderId, student.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentDialog,
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Student'),
      ),
    );
  }
}
