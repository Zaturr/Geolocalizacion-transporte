// lib/edit_admin_settings_screen.dart

import 'package:flutter/material.dart';

class EditAdminSettingsScreen extends StatelessWidget {
  const EditAdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de la Administración'),
      ),
      body: const Center(
        child: Text('Aquí puedes editar la configuración y la información de la administración.'),
      ),
    );
  }
}