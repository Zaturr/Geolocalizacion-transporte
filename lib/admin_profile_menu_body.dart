// lib/admin_profile_menu_body.dart

import 'package:flutter/material.dart';
import 'profile_menu_body.dart'; // Import the base class

class AdminProfileMenuBody extends ProfileMenuBody {
  // Declare the new callbacks as final fields within this class
  final VoidCallback onNavigateToManageUsers;
  final VoidCallback onNavigateToEditAdminSettings;

  const AdminProfileMenuBody({
    super.key,
    required super.onCloseMenu,
    required super.onShowDashboardSelector,
    required super.onLogout,
    required super.onNavigateToSettings,
    // IMPORTANT: ProfileMenuBody requires onCreateOrganization.
    // We pass a no-op function if this specific AdminProfileMenuBody doesn't use it.
    required VoidCallback onCreateOrganization, // Re-introduce for super call
    required super.onNavigateToSupport,
    required this.onNavigateToManageUsers, // CORRECT: Initialize with 'this.'
    required this.onNavigateToEditAdminSettings, // CORRECT: Initialize with 'this.'
  }) : super(
    onCreateOrganization: onCreateOrganization, // Pass to super's constructor
  );
  // Note: super.onCreateOrganization: onCreateOrganization is an alternative syntax
  // but passing it directly as a named argument to super is often clearer.

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
        ListTile(
          title: Text("Editar Configuración de la Administración", style: TextStyle(color: colorScheme.onSurface)),
          onTap: () {
            onCloseMenu();
            onNavigateToEditAdminSettings(); // Now 'this.onNavigateToEditAdminSettings' is correctly defined
          },
        ),
        ListTile(
          title: Text("Administrar Usuarios", style: TextStyle(color: colorScheme.onSurface)),
          onTap: () {
            onCloseMenu();
            onNavigateToManageUsers(); // Now 'this.onNavigateToManageUsers' is correctly defined
          },
        ),
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