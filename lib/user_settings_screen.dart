import 'package:flutter/material.dart';

class UserSettingsScreen extends StatelessWidget {
  const UserSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes de Usuario'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Aquí podrás cambiar tu contraseña, correo, nombre, y validar permisos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement password change logic
                  print('Password Change pressed');
                },
                child: const Text('Cambiar Contraseña'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement email change logic
                  print('Email Change pressed');
                },
                child: const Text('Cambiar Correo'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement name change logic
                  print('Name Change pressed');
                },
                child: const Text('Cambiar Nombre'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement permission validation logic
                  print('Validate Permissions pressed');
                },
                child: const Text('Validar Permisos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}