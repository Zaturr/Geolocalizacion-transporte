import 'package:flutter/material.dart';
import '../route_list_screen.dart'; // Asegúrate de que la ruta sea correcta

class AdminQuickActionsBar extends StatelessWidget {
  const AdminQuickActionsBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Acceder al ColorScheme del tema actual para consistencia visual
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Define your quick action buttons
    // En una aplicación real, estos tendrían callbacks onTap reales para navegar o realizar acciones
    final List<Map<String, dynamic>> actions = [
      {
        'label': 'Rutas',
        'icon': Icons.alt_route,
        'onTap': () {
          // Navegar a RouteListScreen cuando se presione el botón "Rutas"
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RouteListScreen()),
          );
        },
      },
      {
        'label': 'Problemas',
        'icon': Icons.report_problem,
        'onTap': () {
          print('Problemas button pressed');
          // TODO: Navigate to Problems/Issues management screen
        },
      },
      {
        'label': 'Mantenimiento',
        'icon': Icons.build,
        'onTap': () {
          print('Mantenimiento button pressed');
          // TODO: Navigate to Maintenance management screen
        },
      },
      {
        'label': 'Placeholder 1',
        'icon': Icons.more_horiz, // Generic icon for placeholder
        'onTap': () {
          print('Placeholder 1 button pressed');
          // TODO: Add functionality later
        },
      },
      {
        'label': 'Placeholder 2',
        'icon': Icons.extension, // Generic icon for placeholder
        'onTap': () {
          print('Placeholder 2 button pressed');
          // TODO: Add functionality later
        },
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones Rápidas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100, // Fixed height for the scrollable bar
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: actions.map((action) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0), // Spacing between buttons
                    child: SizedBox(
                      width: 90, // Fixed width for each button card
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        elevation: 2,
                        clipBehavior: Clip.antiAlias, // Ensure content respects card shape
                        child: InkWell( // Makes the whole card tappable
                          onTap: action['onTap'],
                          borderRadius: BorderRadius.circular(12.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  action['icon'] as IconData,
                                  size: 32,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  action['label'] as String,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
