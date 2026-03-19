import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  final VoidCallback onRoleSelected;

  const RoleSelectionScreen({super.key, required this.onRoleSelected});

  Future<void> _setRole(BuildContext context, String role) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      onRoleSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Select your Role",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _setRole(context, 'admin'),
              child: const Text('I am an Admin'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _setRole(context, 'officer'),
              child: const Text('I am an Officer'),
            ),
          ],
        ),
      ),
    );
  }
}
