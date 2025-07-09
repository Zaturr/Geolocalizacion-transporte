// lib/edit_organization_settings_screen.dart

import 'package:flutter/material.dart';

class EditOrganizationSettingsScreen extends StatelessWidget {
  const EditOrganizationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Ajustes de Organización'),
      ),
      body: const Center(
        child: Text('Aquí se configurarán los ajustes de la organización para el conductor.'),
      ),
    );
  }
}