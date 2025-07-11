import 'package:flutter/material.dart';
//import 'package:latlong2/latlong.dart'; // Para LatLng (aunque Google Maps usa su propio LatLng, lo mantenemos por si acaso)
import 'package:supabase_flutter/supabase_flutter.dart'; // Para Supabase
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm; // Alias para evitar conflictos con latlong2
import 'dart:async'; // Para usar Timer
import 'route_creation_map_widget.dart'; // Importa el nuevo widget de mapa

class RouteCreationScreen extends StatefulWidget {
  // Add the organizationId parameter here
  final String organizationId;

  const RouteCreationScreen({
    Key? key,
    required this.organizationId, // Mark it as required
  }) : super(key: key);

  @override
  State<RouteCreationScreen> createState() => _RouteCreationScreenState();
}

class _RouteCreationScreenState extends State<RouteCreationScreen> {
  gm.LatLng _currentMarkerLatLng = const gm.LatLng(10.4801, -66.9036);
  List<Map<String, dynamic>> _stops = [];
  bool _isLoading = false;

  Set<gm.Marker> _addedStopMarkers = {};

  String? _topMessage;
  Color? _topMessageColor;
  bool _showTopMessage = false;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    debugPrint('RouteCreationScreen: initState - Pantalla de creación de ruta inicializada.');
    debugPrint('RouteCreationScreen: organizationId recibido: ${widget.organizationId}'); // Verify the ID
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    debugPrint('RouteCreationScreen: dispose - Recursos de la pantalla de creación de ruta liberados.');
    super.dispose();
  }

  void _showCustomTopMessage(String message, {Color? backgroundColor}) {
    _messageTimer?.cancel();

    setState(() {
      _topMessage = message;
      _topMessageColor = backgroundColor;
      _showTopMessage = true;
    });

    _messageTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showTopMessage = false;
        });
      }
    });
    debugPrint('RouteCreationScreen: Mensaje superior mostrado: "$message"');
  }

  void _onMapCameraIdle(gm.LatLng newCenter) {
    setState(() {
      _currentMarkerLatLng = newCenter;
    });
    debugPrint('RouteCreationScreen: onMapCameraIdle - Marcador central actualizado a Lat: ${newCenter.latitude}, Lon: ${newCenter.longitude}');
  }

  Future<void> _addStop() async {
    debugPrint('RouteCreationScreen: _addStop - Intentando agregar una parada.');
    final TextEditingController stopNameController = TextEditingController();
    final String? stopName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nombre de la Parada'),
          content: TextField(
            controller: stopNameController,
            decoration: const InputDecoration(hintText: "Ej: Parada Principal"),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                debugPrint('RouteCreationScreen: _addStop - Diálogo de nombre de parada cancelado.');
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('Agregar'),
              onPressed: () {
                if (stopNameController.text.trim().isNotEmpty) {
                  debugPrint('RouteCreationScreen: _addStop - Nombre de parada ingresado: "${stopNameController.text.trim()}"');
                  Navigator.pop(context, stopNameController.text.trim());
                } else {
                  debugPrint('RouteCreationScreen: _addStop - Error: El nombre de la parada está vacío.');
                  _showCustomTopMessage('El nombre de la parada no puede estar vacío.', backgroundColor: Colors.orange);
                }
              },
            ),
          ],
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        );
      },
    );

    if (stopName != null && mounted) {
      setState(() {
        _stops.add({
          'name': stopName,
          'latitude': _currentMarkerLatLng.latitude,
          'longitude': _currentMarkerLatLng.longitude,
        });
        _addedStopMarkers.add(
          gm.Marker(
            markerId: gm.MarkerId('stop_${_stops.length}'),
            position: _currentMarkerLatLng,
            icon: gm.BitmapDescriptor.defaultMarkerWithHue(gm.BitmapDescriptor.hueRed),
            infoWindow: gm.InfoWindow(title: stopName),
          ),
        );
        debugPrint('RouteCreationScreen: _addStop - Parada agregada localmente: $stopName en Lat: ${_currentMarkerLatLng.latitude}, Lon: ${_currentMarkerLatLng.longitude}');
        _showCustomTopMessage('Parada "$stopName" agregada.', backgroundColor: Colors.green);
      });
    } else {
      debugPrint('RouteCreationScreen: _addStop - No se agregó la parada (nombre nulo o widget desmontado).');
    }
  }

  Future<void> _finishRoute() async {
    debugPrint('RouteCreationScreen: _finishRoute - Intentando finalizar y guardar la ruta.');
    if (_stops.length < 2) {
      if (mounted) {
        debugPrint('RouteCreationScreen: _finishRoute - Error: Menos de 2 paradas. Actuales: ${_stops.length}');
        _showCustomTopMessage('Una ruta debe tener al menos 2 paradas.', backgroundColor: Colors.orange);
      }
      return;
    }

    // Check if organizationId is available before proceeding
    // Note: widget.organizationId is a required String, so it won't be null.
    // This null check can technically be removed if you are certain it's always passed.
    // However, keeping it doesn't hurt and adds a layer of safety.
    if (widget.organizationId == null) {
      if (mounted) {
        _showCustomTopMessage('Error: No se pudo obtener la ID de la organización para guardar la ruta.', backgroundColor: Theme.of(context).colorScheme.error);
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final TextEditingController routeNameController = TextEditingController();
    final String? routeName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nombre de la Ruta'),
          content: TextField(
            controller: routeNameController,
            decoration: const InputDecoration(hintText: "Ej: Ruta Caracas - La Guaira"),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                debugPrint('RouteCreationScreen: _finishRoute - Diálogo de nombre de ruta cancelado.');
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('Guardar Ruta'),
              onPressed: () {
                if (routeNameController.text.trim().isNotEmpty) {
                  debugPrint('RouteCreationScreen: _finishRoute - Nombre de ruta ingresado: "${routeNameController.text.trim()}"');
                  Navigator.pop(context, routeNameController.text.trim());
                } else {
                  debugPrint('RouteCreationScreen: _finishRoute - Error: El nombre de la ruta está vacío.');
                  _showCustomTopMessage('El nombre de la ruta no puede estar vacío.', backgroundColor: Colors.orange);
                }
              },
            ),
          ],
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        );
      },
    );

    if (routeName == null || !mounted) {
      debugPrint('RouteCreationScreen: _finishRoute - No se finalizó la ruta (nombre nulo o widget desmontado).');
      return;
    }

    setState(() {
      _isLoading = true;
    });
    debugPrint('RouteCreationScreen: _finishRoute - Estado de carga establecido en true.');

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    debugPrint('RouteCreationScreen: _finishRoute - User ID: $userId');

    if (userId == null) {
      if (mounted) {
        debugPrint('RouteCreationScreen: _finishRoute - Error: Usuario no autenticado.');
        _showCustomTopMessage('Error: Usuario no autenticado.', backgroundColor: Theme.of(context).colorScheme.error);
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // 1. Insertar la nueva ruta en la tabla 'routes'
      // Columns: id, name, created_at, created_by_uid, organization_id, visibility
      debugPrint('RouteCreationScreen: _finishRoute - Intentando insertar ruta en Supabase...');
      final List<Map<String, dynamic>> routeResponse = await supabase
          .from('routes')
          .insert({
            'name': routeName,
            'created_by_uid': userId,
            'organization_id': widget.organizationId, // Ensure organizationId is passed
            'visibility': true, // Assuming default visibility is true based on schema.
          })
          .select();

      if (routeResponse.isEmpty || routeResponse.first['id'] == null) {
        debugPrint('RouteCreationScreen: _finishRoute - Error: No se pudo obtener el ID de la ruta creada.');
        throw Exception('No se pudo obtener el ID de la ruta creada.');
      }

      final String routeId = routeResponse.first['id'] as String;
      debugPrint('RouteCreationScreen: _finishRoute - Ruta insertada con ID: $routeId');
      // Added this line for debugging foreign key issues
      debugPrint('RouteCreationScreen: _finishRoute - Attempting to insert paradas with routeId: $routeId');

      // 2. Insertar cada parada en la tabla 'paradas'
      // Now using 'organizacion_id' instead of 'creado_por'
      // Columns now are: id, Ruta (FK to routes.id), organizacion_id (FK to organizations.id), Nombre_Parada, Coordenadas
      debugPrint('RouteCreationScreen: _finishRoute - Insertando ${_stops.length} paradas...');
      for (int i = 0; i < _stops.length; i++) {
        await supabase.from('paradas').insert({
          'Ruta': routeId, // Link to the created route ID
          'Nombre_Parada': _stops[i]['name'], // Column name from schema (case-sensitive)
          'Coordenadas': '${_stops[i]['latitude']},${_stops[i]['longitude']}', // Combined lat/lon into 'Coordenadas' (text)
          'organizacion_id': widget.organizationId, // <--- CHANGED THIS LINE
        });
        debugPrint('RouteCreationScreen: _finishRoute - Parada ${i + 1} insertada: ${_stops[i]['name']}');
      }

      if (mounted) {
        debugPrint('RouteCreationScreen: _finishRoute - Ruta y paradas guardadas exitosamente.');
        _showCustomTopMessage('Ruta creada y paradas guardadas exitosamente!', backgroundColor: Colors.green);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } on PostgrestException catch (e) {
      String errorMessage = e.message;
      if (e.code != null && (e.code is String) && (e.code as String).isNotEmpty) {
        errorMessage += '\nCódigo: ${e.code}';
      }
      if (e.details != null && (e.details is String) && (e.details as String).isNotEmpty) {
        errorMessage += '\nDetalles: ${e.details}';
      }
      if (e.hint != null && (e.hint is String) && (e.hint as String).isNotEmpty) {
        errorMessage += '\nSugerencia: ${e.hint}';
      }

      debugPrint('RouteCreationScreen: _finishRoute - PostgrestException: $errorMessage');
      if (mounted) {
        _showCustomTopMessage('Error de base de datos: $errorMessage', backgroundColor: Theme.of(context).colorScheme.error);
      }
    } catch (e) {
      debugPrint('RouteCreationScreen: _finishRoute - Error inesperado: $e');
      if (mounted) {
        _showCustomTopMessage('Ocurrió un error inesperado: $e', backgroundColor: Theme.of(context).colorScheme.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('RouteCreationScreen: _finishRoute - Estado de carga establecido en false.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Ruta'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: Stack(
        children: [
          RouteCreationMapWidget(
            initialCameraPosition: _currentMarkerLatLng,
            onCameraIdle: _onMapCameraIdle,
            additionalMarkers: _addedStopMarkers,
          ),
          Positioned(
            bottom: 16.0,
            left: 16.0,
            right: 16.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_stops.isNotEmpty)
                  Container(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.2),
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _stops.length,
                      itemBuilder: (context, index) {
                        final stop = _stops[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Text('${index + 1}', style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                          ),
                          title: Text(stop['name'], style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          // Display coordinates from the combined string, if desired
                          subtitle: Text('Lat: ${stop['latitude'].toStringAsFixed(4)}, Lon: ${stop['longitude'].toStringAsFixed(4)}',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _addStop,
                        icon: const Icon(Icons.add_location_alt),
                        label: const Text('Agregar Parada'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _finishRoute,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Terminar Ruta'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Theme.of(context).colorScheme.onSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          Positioned(
            top: 16.0,
            left: 16.0,
            right: 16.0,
            child: AnimatedOpacity(
              opacity: _showTopMessage ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _topMessage != null
                  ? Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(8.0),
                      color: _topMessageColor ?? Theme.of(context).colorScheme.surfaceContainerHigh,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Text(
                          _topMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}