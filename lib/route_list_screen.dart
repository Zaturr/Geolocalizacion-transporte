import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'route_creation_screen.dart'; // Importa la pantalla de creación de rutas

class RouteListScreen extends StatefulWidget {
  const RouteListScreen({Key? key}) : super(key: key);

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  List<Map<String, dynamic>> _routes = [];
  bool _isLoading = true;
  String? _organizationId; // Para filtrar rutas por organización

  @override
  void initState() {
    super.initState();
    _fetchUserOrganizationAndRoutes();
  }

  // Obtiene la ID de la organización del usuario actual y luego las rutas
  Future<void> _fetchUserOrganizationAndRoutes() async {
    setState(() {
      _isLoading = true;
    });
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado.')),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Query the 'organizations' table to find the organization created by the current user.
      final List<dynamic> orgResponse = await supabase
          .from('organizations') // Query the organizations table
          .select('id') // Select the organization's ID
          .eq('created_by', userId) // Where the organization was created by the current user
          .limit(1); // Assuming a user manages routes for their primary created organization

      if (orgResponse.isNotEmpty && orgResponse.first['id'] != null) {
        _organizationId = orgResponse.first['id'] as String; // The organization's ID is in the 'id' column
        debugPrint('RouteListScreen: Organization ID found for user: $_organizationId');
        await _fetchRoutes(); // Now that we have the organization, we can fetch its routes
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontró una organización creada por este usuario.')),
          );
        }
        setState(() {
          _isLoading = false;
        });
      }
    } on PostgrestException catch (e) {
      debugPrint('RouteListScreen: PostgrestException al obtener la organización: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener la organización: ${e.message}')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('RouteListScreen: Error inesperado al obtener la organización: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocurrió un error inesperado al obtener la organización: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetches routes associated with the current organization
  Future<void> _fetchRoutes() async {
    if (_organizationId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo determinar la organización del usuario para cargar las rutas.')),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('routes')
          .select('id, name')
          .eq('organization_id', _organizationId!) // Filter by the fetched organization_id
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _routes = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } on PostgrestException catch (e) {
      debugPrint('RouteListScreen: PostgrestException al cargar rutas: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar rutas: ${e.message}')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('RouteListScreen: Error inesperado al cargar rutas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocurrió un error inesperado al cargar rutas: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Rutas'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.route_outlined, size: 80, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(
                        'No hay rutas creadas para tu organización.',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _routes.length,
                  itemBuilder: (context, index) {
                    final route = _routes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(
                          route['name'] ?? 'Ruta sin nombre',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          route['description'] ?? 'Sin descripción',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        onTap: () {
                          // TODO: Implement navigation to route details or edit screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ver detalles de la ruta: ${route['name']}')),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Pass the organization ID to the creation screen
          if (_organizationId != null) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RouteCreationScreen(
                  organizationId: _organizationId!, // Pass the organization ID
                ),
              ),
            );
            // On return from the creation screen, reload the routes
            _fetchUserOrganizationAndRoutes();
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No se puede crear una ruta sin una organización asociada. Por favor, asegúrese de haber creado una organización.')),
              );
            }
          }
        },
        label: const Text('Crear Nueva Ruta'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}