// lib/company_vehicles_list.dart

import 'package:flutter/material.dart';

class CompanyVehiclesList extends StatelessWidget {
  const CompanyVehiclesList({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Placeholder data for registered vehicles and their drivers
    final List<Map<String, String>> vehicles = [
      {'plate': 'ABC-123', 'model': 'Toyota Hilux', 'driver': 'Juan Pérez'},
      {'plate': 'XYZ-789', 'model': 'Ford F-150', 'driver': 'María García'},
      {'plate': 'DEF-456', 'model': 'Chevrolet D-Max', 'driver': 'Carlos Ruiz'},
      {'plate': 'GHI-012', 'model': 'Nissan Frontier', 'driver': 'Ana López'},
      {'plate': 'JKL-345', 'model': 'Mitsubishi L200', 'driver': 'Pedro Gómez'},
      {'plate': 'MNO-678', 'model': 'Renault Alaskan', 'driver': 'Luisa Fernández'},
      {'plate': 'PQR-901', 'model': 'Volkswagen Amarok', 'driver': 'Miguel Sánchez'},
      {'plate': 'STU-234', 'model': 'Mercedes-Benz X-Class', 'driver': 'Sofía Díaz'},
      {'plate': 'VWX-567', 'model': 'Isuzu D-Max', 'driver': 'Ricardo Castro'},
      // Add more placeholder data to make it scrollable
      {'plate': 'ZYX-987', 'model': 'Toyota Corolla', 'driver': 'Elena Vargas'},
      {'plate': 'FED-654', 'model': 'Honda Civic', 'driver': 'Pablo Herrera'},
      {'plate': 'IHG-321', 'model': 'Hyundai Elantra', 'driver': 'Gabriela Morales'},
      {'plate': 'LKJ-098', 'model': 'Kia Cerato', 'driver': 'Daniel Ortega'},
      {'plate': 'ONM-765', 'model': 'Mazda 3', 'driver': 'Carolina Silva'},
    ];

    return Card(
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vehículos Registrados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            // Use ListView.builder for efficient vertical scrolling
            ListView.builder(
              shrinkWrap: true, // Important: makes ListView take only needed space
              physics: const NeverScrollableScrollPhysics(), // Prevents nested scrolling conflicts
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.directions_car, color: colorScheme.secondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Placa: ${vehicle['plate']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Modelo: ${vehicle['model']}',
                              style: TextStyle(color: colorScheme.onSurfaceVariant),
                            ),
                            Text(
                              'Conductor: ${vehicle['driver']}',
                              style: TextStyle(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      // You could add action icons here, e.g., edit or view details
                      IconButton(
                        icon: Icon(Icons.info_outline, color: colorScheme.primary),
                        onPressed: () {
                          print('View details for ${vehicle['plate']}');
                          // TODO: Navigate to vehicle details screen
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}