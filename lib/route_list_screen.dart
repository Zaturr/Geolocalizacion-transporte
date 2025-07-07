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
      // Primero, obtener la organización a la que pertenece el usuario (si es admin)
      // Asumiendo que el usuario admin está vinculado a una organización a través de user_organizations
      final List<dynamic> userOrgResponse = await supabase
          .from('user_organizations')
          .select('organization_id')
          .eq('user_id', userId)
          .eq('role_in_organization', 'admin') // Solo si el usuario es admin de esa organización
          .limit(1);

      if (userOrgResponse.isNotEmpty && userOrgResponse.first['organization_id'] != null) {
        _organizationId = userOrgResponse.first['organization_id'] as String;
        await _fetchRoutes(); // Ahora que tenemos la organización, podemos buscar sus rutas
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontró una organización asociada a este administrador.')),
          );
        }
        setState(() {
          _isLoading = false;
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener la organización: ${e.message}')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
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
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('routes')
          .select('id, name, description')
          .eq('organization_id', _organizationId!) // <-- Corrección aquí: Usar el operador de aserción nula
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _routes = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar rutas: ${e.message}')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
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
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RouteCreationScreen()),
          );
          // Al volver de la pantalla de creación, recargar las rutas
          _fetchUserOrganizationAndRoutes();
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
