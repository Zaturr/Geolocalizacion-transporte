import 'package:flutter/material.dart';

class DashboardAdmin extends StatelessWidget {
  const DashboardAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("dashboard_admin.dart")),
      body: const Center(child: Text("Bienvenido_Admin!")),//todo remplazar admin por el nombre de usuario
      //todo Agregar los conductores En linea--->backend??
      //todo Mostrar las rutas activas--->policies backend
      //todo administrar organizacion (agregar/remover vehiculos, conductores)--->trigger backend
    );
  }
}



