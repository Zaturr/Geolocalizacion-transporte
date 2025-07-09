// lib/manage_users_screen.dart

import 'package:flutter/material.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Usuarios'),
      ),
      body: const Center(
        child: Text('Aquí se mostrará la interfaz para administrar usuarios.'),
      ),
    );
  }
}