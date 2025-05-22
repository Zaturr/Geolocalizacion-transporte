import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pathfinder/location_permission_widget.dart';
import 'dashboard_admin.dart';
import 'dashboard_driver.dart';
import 'map_screen.dart';

class DashboardClient extends StatelessWidget {
  const DashboardClient({super.key});
//todo navbar para ajustes de usuario
  //todo cambio de correo--->trigger backend
  //todo cambio de contraseña--->trigger backend
  //todo agregar/cambiar telefono--->trigger backend
  //todo foto de usuario--->new table backend
  //todo boton para crear organizacion (transforma al usuario en Administrador)--->trigger backend
  //todo boton para aplicar para ser conductor (transforma al usuario en conductor)--->trigger backend
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Client Dashboard")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Client View"),
            const SizedBox(height: 20),
            LocationPermissionWidget(),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: const MapScreen(),
            ),
            ElevatedButton(
              onPressed: () => _showDashboardSelector(context),
              child: const Text("Switch Dashboard (Debug)"),
            ),
          ],
        ),
      ),
    );
  }

  void _showDashboardSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Dashboard"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Admin"),
              onTap: () => _navigateTo(context, const DashboardAdmin()),
            ),
            ListTile(
              title: const Text("Driver"),
              onTap: () => _navigateTo(context, const DashboardDriver()),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}