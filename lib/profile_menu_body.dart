import 'package:flutter/material.dart';

class ProfileMenuBody extends StatelessWidget {
  final VoidCallback onCloseMenu;
  final VoidCallback onShowDashboardSelector;
  final VoidCallback onLogout;
  final VoidCallback onNavigateToSettings; // NEW: For user settings
  final VoidCallback onCreateOrganization; // NEW: For creating an organization
  final VoidCallback onNavigateToSupport;  // NEW: For support screen

  const ProfileMenuBody({
    Key? key,
    required this.onCloseMenu,
    required this.onShowDashboardSelector,
    required this.onLogout,
    required this.onNavigateToSettings, // NEW
    required this.onCreateOrganization, // NEW
    required this.onNavigateToSupport,  // NEW
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (commented out as per your previous request)
        // Padding(
        //   padding: const EdgeInsets.all(16.0),
        //   child: Row(
        //     children: [
        //       CircleAvatar(
        //         backgroundColor: colorScheme.secondaryContainer,
        //         child: Icon(
        //           Icons.person,
        //           color: colorScheme.onSecondaryContainer,
        //         ),
        //       ),
        //       const SizedBox(width: 16.0),
        //       Text(
        //         "Nombre del Cliente",
        //         style: TextStyle(
        //           fontWeight: FontWeight.bold,
        //           color: colorScheme.onSurface,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        Divider(
          color: colorScheme.onSurface.withOpacity(0.12),
        ),
        ListTile(
          title: Text("Ajustes de Usuario", style: TextStyle(color: colorScheme.onSurface)),
          onTap: () {
            onCloseMenu(); // Close menu first
            onNavigateToSettings(); // Call the new callback
          },
        ),
        ListTile(
          title: Text("Crear una Organización", style: TextStyle(color: colorScheme.onSurface)),
          onTap: () {
            onCloseMenu(); // Close menu first
            onCreateOrganization(); // Call the new callback
          },
        ),
        ListTile(
          title: Text("Soporte", style: TextStyle(color: colorScheme.onSurface)),
          onTap: () {
            onCloseMenu(); // Close menu first
            onNavigateToSupport(); // Call the new callback
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