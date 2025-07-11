// map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:ui' as ui; // Alias 'dart:ui' to 'ui' for clarity
import 'package:android_intent_plus/android_intent.dart'; // For Android location settings
import 'package:supabase_flutter/supabase_flutter.dart';

class MapScreen extends StatefulWidget {
  // NEW: Accept routeStops in the constructor
  final List<Map<String, dynamic>> routeStops;

  const MapScreen({Key? key, this.routeStops = const []}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {}; // Set to store polylines for routes
  BitmapDescriptor _currentLocationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _busStopIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _busIcon = BitmapDescriptor.defaultMarker; // New: Icon for the simulated bus
  LatLng? _initialCameraPosition;
  StreamSubscription<Position>? _positionSubscription;
  bool _isLoading = true;
  bool _isFollowingUser = true; // Controls if the map follows the user's location
  List<LatLng> _busStopCoordinates = []; // List to store all fetched bus stop coordinates

  LatLng? _simulatedBusPosition; // New: Current simulated position of the bus
  int _busRouteIndex = 0; // New: Index of the current bus stop in the simulation
  Timer? _simulationTimer; // New: Timer for bus movement simulation
  bool _isBusSimulating = false; // New: Flag to control simulation start/stop

  // Removed direct Supabase client as fetching is now handled by DashboardClient
  // final String _busStopsTable = 'paradas';
  // final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // Initialize map components: permissions, icons
    _initializeMap();
    // Process initial route stops passed from the DashboardClient
    _updateMarkersAndPolyline(widget.routeStops);
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the routeStops change, update the markers and polyline
    if (widget.routeStops != oldWidget.routeStops) {
      _updateMarkersAndPolyline(widget.routeStops);
    }
  }

  @override
  void dispose() {
    // Cancel any active location subscriptions
    _positionSubscription?.cancel();
    _simulationTimer?.cancel(); // New: Cancel simulation timer
    // Dispose of the map controller to free up resources
    _mapController?.dispose();
    super.dispose();
  }

  /// Initializes map components: checks permissions, loads custom icons.
  /// (Removed _fetchBusStopsFromSupabase from here as it's now external)
  Future<void> _initializeMap() async {
    await _checkLocationPermission();
    await _loadCustomMarkerIcons();
    await _loadBusIcon(); // Load bus icon
    // _isLoading will be set to false in _startLocationUpdates after getting initial position
  }

  /// Loads custom marker icons from assets.
  Future<void> _loadCustomMarkerIcons() async {
    // Load user's current location icon
    _currentLocationIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/user_location_icon.png', // Ensure this asset is in your pubspec.yaml
    );

    // Load and resize bus stop icon
    _busStopIcon = await _resizeAndConvert(
      assetPath: 'assets/bus_stop_icon.png', // Ensure this asset is in your pubspec.yaml
      scale: 1.0, // Scale factor for the icon size
    );
  }

  /// New: Loads the custom icon for the simulated bus.
  Future<void> _loadBusIcon() async {
    _busIcon = await _resizeAndConvert(
      assetPath: 'assets/bus_icon.png', // Ensure this asset is in your pubspec.yaml
      scale: 3, // Scale factor for the icon size
    );
  }

  /// Resizes an image asset and converts it to a BitmapDescriptor.
  Future<BitmapDescriptor> _resizeAndConvert({
    required String assetPath,
    required double scale,
  }) async {
    final data = await DefaultAssetBundle.of(context).load(assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: (48 * scale).round(), // Adjust target width based on scale
      targetHeight: (48 * scale).round(), // Adjust target height based on scale
    );
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception("Failed to convert image to byte data.");
    }
    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }

  /// MODIFIED: This method now takes a list of stops and updates the map.
  /// It no longer fetches from Supabase directly.
  void _updateMarkersAndPolyline(List<Map<String, dynamic>> stops) {
    if (!mounted) return;

    setState(() {
      // Clear existing bus stop markers and polylines before adding new ones
      _markers.removeWhere((marker) => marker.markerId.value.startsWith('busStop_'));
      _polylines.clear();
      _busStopCoordinates.clear(); // Clear the list before repopulating

      for (final stop in stops) {
        final String? name = stop['Nombre_Parada'] as String?;
        final String? coordinatesRaw = stop['Coordenadas'] as String?;

        if (name != null && coordinatesRaw != null) {
          final LatLng? coordinates = _parseCoordinates(coordinatesRaw);
          if (coordinates != null) {
            // Add marker for bus stops
            _markers.add(
              Marker(
                markerId: MarkerId('busStop_${stops.indexOf(stop)}'), // Use index for unique ID
                position: coordinates,
                icon: _busStopIcon,
                anchor: const Offset(0.5, 0.5),
                infoWindow: InfoWindow(
                  title: name,
                  snippet: 'Parada',
                ),
              ),
            );
            // Add all bus stop coordinates to the list for the polyline
            _busStopCoordinates.add(coordinates);
          }
        }
      }

      // Create a polyline covering all fetched bus stops for the current route
      if (_busStopCoordinates.length >= 2) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('current_route_polyline'), // Unique ID for the polyline
            points: _busStopCoordinates,
            color: Colors.red, // Color of the route line
            width: 5, // Width of the route line
            jointType: JointType.round, // Smooth joints
            startCap: Cap.roundCap, // Round caps at start
            endCap: Cap.roundCap, // Round caps at end
          ),
        );
        // Set initial simulated bus position to the first bus stop of the new route
        _simulatedBusPosition = _busStopCoordinates.first;
        _busRouteIndex = 0; // Reset bus index for new route
        _updateSimulatedBusMarker(); // Update the bus marker's position
        // If simulation was active, restart it for the new route
        if (_isBusSimulating) {
          _stopBusSimulation();
          _startBusSimulation();
        }
      } else {
        // If less than 2 stops, clear bus simulation and show message
        _stopBusSimulation();
        _simulatedBusPosition = null; // Clear bus position
        _updateSimulatedBusMarker(); // Remove bus marker
        if (_busStopCoordinates.isNotEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay suficientes paradas para trazar una ruta.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay paradas para la ruta seleccionada.')),
          );
        }
      }
    });
  }


  /// Parses a coordinate string "latitude,longitude" into a LatLng object.
  LatLng? _parseCoordinates(String coordinatesString) {
    try {
      final parts = coordinatesString.split(',');
      if (parts.length == 2) {
        final latitude = double.parse(parts[0].trim());
        final longitude = double.parse(parts[1].trim());
        return LatLng(latitude, longitude);
      }
    } catch (e) {
      // Log parsing errors if any coordinate string is malformed
      print('Error parsing coordinates: $coordinatesString - $e');
    }
    return null;
  }

  /// Checks and requests location permissions.
  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;
    if (!status.isGranted) {
      final result = await Permission.location.request();
      if (!result.isGranted) {
        if (mounted) {
          await _showPermissionDeniedDialog();
        }
        setState(() { _isLoading = false; }); // Stop loading if permission denied
        return;
      }
    }

    // Check if location services are enabled on the device
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        await _showLocationServiceDisabledDialog();
      }
      setState(() { _isLoading = false; }); // Stop loading if service disabled
      return;
    }

    await _startLocationUpdates();
  }

  /// Starts listening for location updates and updates the map.
  Future<void> _startLocationUpdates() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _initialCameraPosition = LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );
          _updateCurrentLocationMarker(); // Update marker for initial position
          _isLoading = false; // Set loading to false once initial position is obtained
        });
      }

      // Listen for continuous location updates
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _updateCurrentLocationMarker(); // Update marker on new location
            if (_isFollowingUser) {
              _updateCameraPosition(); // Animate camera if following user
            }
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de ubicación: ${e.toString()}')),
        );
        setState(() { _isLoading = false; }); // Stop loading on error
      }
    }
  }

  /// Updates the marker for the user's current location on the map.
  void _updateCurrentLocationMarker() {
    // Remove old current location marker
    _markers.removeWhere((marker) => marker.markerId.value == 'currentLocation');

    // Add new current location marker if position and icon are available
    if (_currentPosition != null && _currentLocationIcon != BitmapDescriptor.defaultMarker) {
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: _currentLocationIcon,
          rotation: _currentPosition!.heading ?? 0, // Rotate marker based on heading
          anchor: const Offset(0.5, 0.5), // Center anchor point
          infoWindow: const InfoWindow(title: 'Tu Ubicación Actual'), // Info window
        ),
      );
    }
  }

  /// Updates the marker for the simulated bus's position on the map.
  void _updateSimulatedBusMarker() {
    _markers.removeWhere((marker) => marker.markerId.value == 'simulatedBus');

    if (_simulatedBusPosition != null && _busIcon != BitmapDescriptor.defaultMarker) {
      _markers.add(
        Marker(
          markerId: const MarkerId('simulatedBus'),
          position: _simulatedBusPosition!,
          icon: _busIcon, // Use the custom bus icon
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: 'Bus Simulado',
            snippet: 'Parada ${(_busRouteIndex + 1).toString().padLeft(2, '0')}', // Formats to "01", "02", etc.
          ),
        ),
      );
    }
  }

  /// Animates the map camera to the current user's location.
  void _updateCameraPosition() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }
  }

  /// Shows a dialog if location permission is denied.
  Future<void> _showPermissionDeniedDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso de Ubicación Requerido'),
        content: const Text('Esta aplicación necesita permiso de ubicación para funcionar correctamente. Por favor, habilítalo en la configuración de la aplicación.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings(); // Opens app settings for the user to enable permission
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  /// Shows a dialog if location services are disabled on the device.
  Future<void> _showLocationServiceDisabledDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Servicio de Ubicación Desactivado'),
        content: const Text('Por favor, habilita los servicios de ubicación para usar esta función.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              const AndroidIntent intent = AndroidIntent(
                action: 'android.settings.LOCATION_SOURCE_SETTINGS',
              );
              intent.launch(); // Opens Android location settings
            },
            child: const Text('Habilitar'),
          ),
        ],
      ),
    );
  }

  /// Callback when the Google Map is created.
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_initialCameraPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _initialCameraPosition!,
            zoom: 15,
          ),
        ),
      );
    }
  }

  /// Callback when the user starts moving the map camera.
  void _onCameraMoveStarted() {
    if (_isFollowingUser) {
      setState(() {
        _isFollowingUser = false; // Stop following if the user moves the map
      });
    }
  }

  /// Toggles whether the map follows the user's location.
  void _toggleFollowUser() {
    setState(() {
      _isFollowingUser = !_isFollowingUser;
      if (_isFollowingUser) {
        _updateCameraPosition(); // If following is enabled, center the map
      }
    });
  }

  /// Starts the bus route simulation.
  void _startBusSimulation() {
    if (_busStopCoordinates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay paradas de bus cargadas para iniciar la simulación.')),
      );
      return;
    }
    if (_isBusSimulating) return; // Prevent starting multiple timers

    setState(() {
      _isBusSimulating = true;
    });

    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Changed to 1 second for faster demo, change to 60 for 1 minute
      _moveBusToNextStop();
    });
  }

  /// Stops the bus route simulation.
  void _stopBusSimulation() {
    _simulationTimer?.cancel();
    setState(() {
      _isBusSimulating = false;
    });
  }

  /// Moves the simulated bus to the next stop in the route.
  void _moveBusToNextStop() {
    if (!mounted || _busStopCoordinates.isEmpty) {
      _stopBusSimulation(); // Stop simulation if no stops or widget disposed
      return;
    }

    setState(() {
      _busRouteIndex = (_busRouteIndex + 1) % _busStopCoordinates.length;
      _simulatedBusPosition = _busStopCoordinates[_busRouteIndex];
      _updateSimulatedBusMarker();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _initialCameraPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialCameraPosition!,
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines, // Display the polylines
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // Disable default location button
            onCameraMoveStarted: _onCameraMoveStarted, // Detect user camera movement
          ),
          Positioned(
            bottom: 100.0,
            right: 16.0,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'followUserBtn', // Unique tag for hero animation
                  onPressed: _toggleFollowUser,
                  backgroundColor: _isFollowingUser ? Colors.blue : Colors.grey,
                  child: const Icon(Icons.navigation_outlined),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'simulateBusBtn', // Unique tag for hero animation
                  onPressed: _isBusSimulating ? _stopBusSimulation : _startBusSimulation,
                  backgroundColor: _isBusSimulating ? Colors.red : Colors.green, // Red when simulating, green when stopped
                  child: Icon(
                    _isBusSimulating ? Icons.pause : Icons.play_arrow, // Pause icon when simulating, play when stopped
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}