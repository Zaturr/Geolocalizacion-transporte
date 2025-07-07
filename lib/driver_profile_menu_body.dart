// lib/driver_profile_menu_body.dart

import 'package:flutter/material.dart';
import 'profile_menu_body.dart'; // Import the base class

class DriverProfileMenuBody extends ProfileMenuBody {
  const DriverProfileMenuBody({
    super.key,
    required super.onCloseMenu,
    required super.onShowDashboardSelector,
    required super.onLogout,
    required super.onNavigateToSettings,
    required super.onCreateOrganization, // This prop is still needed for the base constructor, even if not directly used here
    required super.onNavigateToSupport,
    required this.onNavigateToEditOrganization, // NEW: Specific callback for driver
  });

  // NEW: Define the specific callback for "Editar ajustes de organización"
  final VoidCallback onNavigateToEditOrganization;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          color: colorScheme.onSurface.withOpacity(0.12),
        ),
        ListTile(
          title: Text("Ajustes de Usuario", style: TextStyle(color: colorScheme.onSurface)),
          onTap: () {
            onCloseMenu();
            onNavigateToSettings();
          },
        ),
        // --- THIS IS THE CUSTOMIZED BUTTON FOR DRIVER ---
        ListTile(
          title: Text("Editar Ajustes de Organización", style: TextStyle(color: colorScheme.onSurface)),
          onTap: () {
            onCloseMenu();
            onNavigateToEditOrganization(); // Call the NEW specific callback
          },
        ),
        // -------------------------------------------------
        ListTile(
          title: Text("Soporte", style: TextStyle(color: colorScheme.onSurface)),
          onTap: () {
            onCloseMenu();
            onNavigateToSupport();
          },
        ),
        ListTile(
          title: Text("Cerrar Sesion", style: TextStyle(color: colorScheme.onSurface)),
          onTap: () {
            onCloseMenu();
            onLogout();
          },
        ),
        ListTile(
          title: Text("Cambiar Dashboard", style: TextStyle(color: colorScheme.onSurface)),
          onTap: () {
            onCloseMenu();
            onShowDashboardSelector();
          },
        ),
      ],
    );
  }
}